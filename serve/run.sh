#!/bin/bash
# Serve the recipe on http://127.0.0.1:5000/v1 (OpenAI-compatible).
#   serve/run.sh               4.0 bpw, 128K (serve/config.yml)
#   serve/run.sh 4.0bpw-256k   4.0 bpw, 256K (serve/configs/4.0bpw-256k.yml); 3.0bpw-256k likewise
# Further arguments go to TabbyAPI's main.py.
#   HIP_VISIBLE_DEVICES  the RX 7900 XTX's HIP index (default 0). Set it so an AMD iGPU (e.g. Ryzen 7000's gfx1036)
#                        is hidden: ROCm would otherwise see it too.
#   MODELS_DIR           where setup/download_model.sh put the weights (default: models/ in this repo)
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
[ -x "$ROOT/tabbyAPI/venv/bin/python" ] || { echo "run.sh: run setup/install.sh first" >&2; exit 1; }
export HIP_VISIBLE_DEVICES=${HIP_VISIBLE_DEVICES:-0}
cfg="$ROOT/serve/config.yml"
if [ -n "${1:-}" ] && [ -f "$ROOT/serve/configs/$1.yml" ]; then cfg="$ROOT/serve/configs/$1.yml"; shift; fi
# TabbyAPI ignores command-line overrides when --config is given, so point model_dir in a local copy instead
if [ -n "${MODELS_DIR:-}" ]; then
  sed "s|^  model_dir: .*|  model_dir: $(cd "$MODELS_DIR" && pwd)|" "$cfg" > "$ROOT/serve/config.local.yml"
  cfg="$ROOT/serve/config.local.yml"
fi
cd "$ROOT/tabbyAPI"
exec venv/bin/python main.py --config "$cfg" "$@"
