#!/bin/bash
# turboderp's Qwen3.8-27B EXL3, pinned. The built-in MTP head is the draft.
#   setup/download_model.sh       SC_4.00bpw_H5 (16 GB), for serve/run.sh and serve/run.sh 4.0bpw-256k
#   setup/download_model.sh 3.0   SC_3.00bpw_H4 (13.5 GB), for serve/run.sh 3.0bpw-256k
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
REPO=turboderp/Qwen3.8-27B-exl3
case "${1:-4.0}" in
  4.0) REVISION=4acd9ad5af224ec9e8815a54d71a033f378a7e9d; NAME=Qwen3.8-27B-exl3-SC4.0 ;;
  3.0) REVISION=86b95530f9d365d90dd24d01a997a8de0cdf6c55; NAME=Qwen3.8-27B-exl3-SC3.0 ;;
  *) echo "download_model.sh: 4.0 or 3.0" >&2; exit 1 ;;
esac
DEST=${MODELS_DIR:-$ROOT/models}/$NAME
HF="$ROOT/tabbyAPI/venv/bin/hf"
[ -x "$HF" ] || HF=$(command -v hf) || { echo "download_model.sh: needs the hf CLI (pip install huggingface_hub)" >&2; exit 1; }
"$HF" download "$REPO" --revision "$REVISION" --local-dir "$DEST"
echo "download_model.sh: $DEST"
