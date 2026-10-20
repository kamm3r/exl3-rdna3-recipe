# Qwen3.8-27B (EXL3) on an AMD RX 7900 XTX: TabbyAPI + upstream ExLlamaV3

Run Qwen3.8-27B as a local OpenAI-compatible server on one Radeon RX 7900 XTX (24 GB, gfx1100), with 128K or 256K context,
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

## Pick a recipe

| Recipe | Start with | Weights | Context and KV cache | Decode (mean of runs) | Peak VRAM (whole card) |
|---|---|---|---|---|---|
| **4.0bpw-128k** (default) | `serve/run.sh` | 4.0 bpw (16 GB) | 128K, 8-bit | 86.1 tok/s, 7 runs | ~21.0 GB |
| **4.0bpw-256k** | `serve/run.sh 4.0bpw-256k` | 4.0 bpw (16 GB) | 256K, 4-bit | 87.8 tok/s, 3 runs | ~21.7 GB |
| **3.0bpw-256k** | `serve/run.sh 3.0bpw-256k` | 3.0 bpw (13.5 GB), `setup/download_model.sh 3.0` | 256K, 8-bit keys / 6-bit values | 93.5 tok/s, 4 runs | ~21.6 GB |

All three use vision, thinking, tool calls and the MTP draft at 3 tokens. Every run passed the six gates below plus the
image check. The 4.0 bpw weights are the better model; 3.0 bpw is a little faster and keeps a higher-precision cache at
256K. At 256K, prefill is about 680 tok/s, so the lab's 213K-token recall prompt takes about 5 minutes. The cache
settings leave at least 1.5 GB free with a desktop and browser on the same card; settings that passed but left less
(4.0 bpw with 6-bit cache at 224K or more, 3.0 bpw with 8-bit cache at 256K, 3.5 bpw with 8-bit cache at 256K) are
not included. 3.5 bpw at 256K with 8-bit cache crashed once when the desktop used 1.2 GB.

## Measured (4.0bpw-128k)

Seven runs of the [local-ai-registry](https://github.com/sybil-solutions/local-ai-registry) lab
(`lab/lab.py try --on endpoint`), each passing all six gates: loads, answers, thinks (separate `reasoning_content`),
calls a tool, recalls a code planted at 85% of the window, and decodes at 15 tok/s or more. Each run also sent one image.

| Run | Decode (tok/s, first 30 s) | Prefill (tok/s) | Recall at 106K tokens | Peak VRAM (whole card) | Image |
|---|---|---|---|---|---|
| 1 | 81.1 | 936 | 114 s | 21,053 MiB | pass |
| 2 | 84.2 | 930 | 114 s | 21,015 MiB | pass |
| 3 | 86.8 | 933 | 114 s | 21,004 MiB | pass |
| 4 | 86.9 | 937 | 114 s | 20,985 MiB | pass |
| 5 | 88.8 | 934 | 114 s | 21,005 MiB | pass |
| 6 | 82.9 | 934 | 114 s | 20,991 MiB | pass |
| 7 | 91.8 | 933 | 114 s | 21,002 MiB | pass |

Mean decode is 86.1 tok/s. It varies run to run because the speed prompt is sampled and MTP's acceptance depends on
the text. Peak VRAM includes the desktop (about 0.5 GB here; a browser with many tabs can add another GB), so about
3 GB of the 24 GB stay free. These runs used `serve/config.yml` without the `allowed_origins` line, which only
affects browser access.

`draft_num_tokens: 3` is the one tuned setting. The model has a single MTP layer, so drafted tokens past the first
reuse it and are accepted less often. With the default of 4, six runs averaged 78.9 tok/s (69.2-92.0); 1, 2 and 5
were slower than 3 in a short benchmark, and a `chunk_size` of 4096 sped prefill up by only 2% for 140 MiB more.

## Install

Requires [uv](https://docs.astral.sh/uv/), git, your user in the `render` and `video` groups, and ~35 GB of disk
(16 GB of weights, ~15 GB for the Python environment).

```bash
git clone https://github.com/kamm3r/exl3-rdna3-recipe && cd exl3-rdna3-recipe
setup/install.sh          # TabbyAPI at e086a65 + the pinned ROCm 10 wheels (setup/requirements.lock.txt) in tabbyAPI/venv
setup/download_model.sh   # the pinned 4.0 bpw weights into models/ (add 3.0 for the 3.0 bpw ones)
serve/run.sh              # http://127.0.0.1:5000/v1, chat page at /ui (or: serve/run.sh 4.0bpw-256k)
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
