#!/bin/bash
# Install TabbyAPI (pinned commit, unpatched) with upstream ExLlamaV3 1.6.3 ROCm 10 wheels for an RDNA3 card.
# Everything ROCm comes from pip (AMD's whl-next indexes); the host only needs the amdgpu kernel driver.
#   GFX=gfx1100 (RX 7900 XTX / XT / GRE). Needs uv (https://docs.astral.sh/uv/) and git.
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
TABBY_COMMIT=e086a65ee27d71b80630ff40bd9a3bd5417442b0
GFX=${GFX:-gfx1100}
INDEXES=(--extra-index-url https://stable.repo.amd.com/rocm/pytorch/whl-next/ --extra-index-url https://stable.repo.amd.com/rocm/core/whl-next/)

command -v uv >/dev/null || { echo "install.sh: uv is required (https://docs.astral.sh/uv/)" >&2; exit 1; }
if [ ! -d "$ROOT/tabbyAPI/.git" ]; then
    git clone https://github.com/theroyallab/tabbyAPI "$ROOT/tabbyAPI"
fi
git -C "$ROOT/tabbyAPI" fetch -q origin "$TABBY_COMMIT" 2>/dev/null || true
git -C "$ROOT/tabbyAPI" checkout -q "$TABBY_COMMIT"
[ -d "$ROOT/tabbyAPI/venv" ] || uv venv -q -p 3.12 "$ROOT/tabbyAPI/venv"
export VIRTUAL_ENV="$ROOT/tabbyAPI/venv"
if [ "$GFX" = gfx1100 ]; then
    # the exact set measured for the recipe
    uv pip install --index-strategy unsafe-best-match "${INDEXES[@]}" -r "$ROOT/setup/requirements.lock.txt"
    uv pip install --no-deps "$ROOT/tabbyAPI"
else
    uv pip install --index-strategy unsafe-best-match "${INDEXES[@]}" "$ROOT/tabbyAPI[rocm]" "amd-torch-device-$GFX"
fi
"$VIRTUAL_ENV/bin/python" -c "import torch, exllamav3; print('torch', torch.__version__, '| GPU visible:', torch.cuda.is_available())"
echo "install.sh: done. Next: setup/download_model.sh, then serve/run.sh"
