#!/bin/bash
# turboderp's Qwen3.8-27B EXL3, SC_4.00bpw_H5 branch (16 GB), pinned. Its built-in MTP head is the draft.
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
REPO=turboderp/Qwen3.8-27B-exl3
REVISION=4acd9ad5af224ec9e8815a54d71a033f378a7e9d
DEST=${MODELS_DIR:-$ROOT/models}/Qwen3.8-27B-exl3-SC4.0
HF="$ROOT/tabbyAPI/venv/bin/hf"
[ -x "$HF" ] || HF=$(command -v hf) || { echo "download_model.sh: needs the hf CLI (pip install huggingface_hub)" >&2; exit 1; }
"$HF" download "$REPO" --revision "$REVISION" --local-dir "$DEST"
echo "download_model.sh: $DEST"
