#!/bin/bash
# Serve the recipe on http://127.0.0.1:5000/v1 (OpenAI-compatible). Extra arguments go to TabbyAPI's main.py.
#   HIP_VISIBLE_DEVICES  the RX 7900 XTX's HIP index (default 0). Set it so an AMD iGPU (e.g. Ryzen 7000's gfx1036)
#                        is hidden: ROCm would otherwise see it too.
#   MODELS_DIR           where setup/download_model.sh put the weights (default: models/ in this repo)
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
[ -x "$ROOT/tabbyAPI/venv/bin/python" ] || { echo "run.sh: run setup/install.sh first" >&2; exit 1; }
export HIP_VISIBLE_DEVICES=${HIP_VISIBLE_DEVICES:-0}
cfg="$ROOT/serve/config.yml"
# TabbyAPI ignores command-line overrides when --config is given, so point model_dir in a local copy instead
if [ -n "${MODELS_DIR:-}" ]; then
  cfg="$ROOT/serve/config.local.yml"
  sed "s|^  model_dir: .*|  model_dir: $(cd "$MODELS_DIR" && pwd)|" "$ROOT/serve/config.yml" > "$cfg"
fi
cd "$ROOT/tabbyAPI"
exec venv/bin/python main.py --config "$cfg" "$@"
