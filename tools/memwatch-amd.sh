#!/bin/bash
# The recipe kit's tools/memwatch.sh columns, with GPU memory read from amdgpu sysfs (the kit reads nvidia-smi, which
# reports nothing on AMD). One CSV line per second; start it before the server, stop it with Ctrl-C.
#   tools/memwatch-amd.sh memwatch.csv      DEV=/sys/class/drm/cardN/device picks the card (default: the largest VRAM)
OUT=${1:-memwatch.csv}
if [ -z "${DEV:-}" ]; then
  best=0
  for d in /sys/class/drm/card*/device; do
    [ -f "$d/mem_info_vram_total" ] || continue
    t=$(cat "$d/mem_info_vram_total"); [ "$t" -gt "$best" ] && { best=$t; DEV=$d; }
  done
fi
[ -n "${DEV:-}" ] || { echo "memwatch-amd.sh: no amdgpu card found" >&2; exit 1; }
echo "t,mem_available_gb,swap_used_gb,gpu_used_mib,gpu_total_mib" > "$OUT"
while true; do
  read -r ma st sf < <(awk '/MemAvailable/{a=$2}/SwapTotal/{t=$2}/SwapFree/{f=$2}END{print a,t,f}' /proc/meminfo)
  g=$(( $(cat $DEV/mem_info_vram_used) / 1048576 )); gt=$(( $(cat $DEV/mem_info_vram_total) / 1048576 ))
  echo "$(date +%s),$(echo "scale=2;$ma/1000000" | bc),$(echo "scale=2;($st-$sf)/1000000" | bc),$g,$gt" >> "$OUT"
  sleep 1
done
