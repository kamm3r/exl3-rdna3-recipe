# Qwen3.8-27B (EXL3) on an AMD RX 7900 XTX: TabbyAPI + upstream ExLlamaV3

Run Qwen3.8-27B as a local OpenAI-compatible server on one Radeon RX 7900 XTX (24 GB, gfx1100), with 128K context,
thinking, tool calling and image input. It uses **unpatched** upstream [TabbyAPI](https://github.com/theroyallab/tabbyAPI)
and the official [ExLlamaV3](https://github.com/turboderp-org/exllamav3) 1.6.3 ROCm 10 wheels: nothing to compile, and
no system ROCm install, only the in-kernel `amdgpu` driver.

| | |
|---|---|
| Model | [`turboderp/Qwen3.8-27B-exl3`](https://huggingface.co/turboderp/Qwen3.8-27B-exl3) `SC_4.00bpw_H5` @ `4acd9ad5` (16 GB), its built-in MTP head as the draft |
| Context | 131,072 tokens, 8-bit K/V cache, one request at a time |
| Vision | on, encoder weights kept in system RAM (`vision_offload`) |
| Engine | TabbyAPI `e086a65`, ExLlamaV3 `1.6.3+rocm10.0`, PyTorch `2.13.0+rocm10.0.0`, Python 3.12 |
| Tested on | RX 7900 XTX 24 GB, Ryzen 7 7800X3D, 32 GB RAM, Nobara 44 (kernel 7.2) |

## Measured

Five runs of the [local-ai-registry](https://github.com/sybil-solutions/local-ai-registry) lab
(`lab/lab.py try --on endpoint`), each passing all six gates: loads, answers, thinks (separate `reasoning_content`),
calls a tool, recalls a code planted at 85% of the window, and decodes at 15 tok/s or more. Each run also sent one image.

| Run | Decode (tok/s, first 30 s) | Prefill (tok/s) | Recall at 106K tokens | Peak VRAM (whole card) | Image |
|---|---|---|---|---|---|
| 1 | 72.5 | 934 | 114 s | 20,961 MiB | pass |
| 2 | 69.2 | 936 | 114 s | 20,999 MiB | pass |
| 3 | 77.7 | 938 | 113 s | 21,540 MiB | pass |
| 4 | 92.0 | 937 | 113 s | 21,524 MiB | pass |
| 5 | 79.5 | 921 | 115 s | 21,577 MiB | pass |

Decode varies run to run because the speed prompt is sampled and MTP's acceptance depends on the text. Peak VRAM
includes the desktop (about 0.5-1 GB here), so about 3 GB of the 24 GB stay free. These five runs used
`serve/config.yml` without the `allowed_origins` line, which only affects browser access.

## Install

Requires [uv](https://docs.astral.sh/uv/), git, your user in the `render` and `video` groups, and ~35 GB of disk
(16 GB of weights, ~15 GB for the Python environment).

```bash
git clone https://github.com/kamm3r/exl3-rdna3-recipe && cd exl3-rdna3-recipe
setup/install.sh          # TabbyAPI at e086a65 + the pinned ROCm 10 wheels (setup/requirements.lock.txt) in tabbyAPI/venv
setup/download_model.sh   # the pinned weights into models/
serve/run.sh              # http://127.0.0.1:5000/v1, chat page at /ui
```

`HIP_VISIBLE_DEVICES` defaults to `0`. If the machine also has an AMD iGPU (Ryzen 7000/9000 desktops do), check with
`rocminfo` that index 0 is the discrete card: ROCm sees the iGPU as a second device. `MODELS_DIR` points
`run.sh` at weights elsewhere. Other RDNA3 cards can try `GFX=gfx1101 setup/install.sh` (resolves the same TabbyAPI
`rocm` extra instead of the lock file); only the 7900 XTX has been tested.

## Use

Any OpenAI client: base URL `http://127.0.0.1:5000/v1`, any API key (auth is off; the server listens on localhost only
and `allowed_origins: []` stops web pages in your browser from reading its responses). Thinking arrives in `reasoning_content`; tool calls are
parsed with `tool_format: qwen3_coder`.

## Tools

- `tools/memwatch-amd.sh out.csv`: the registry kit's `memwatch.sh` columns with GPU memory read from amdgpu sysfs.
- `tools/vision_check.py`: sends one generated image and checks the answer.

Independent project; not affiliated with TabbyAPI, ExLlamaV3, Qwen or AMD.
