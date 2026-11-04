#!/usr/bin/env bash
# AMD GPU usage, temperature and VRAM for waybar (JSON output)

dev=""
for d in /sys/class/drm/card*/device; do
  [[ -r $d/gpu_busy_percent ]] && { dev=$d; break; }
done
[[ -z $dev ]] && { echo '{"text": "?", "tooltip": "GPU not found"}'; exit 0; }

busy=$(cat "$dev/gpu_busy_percent")

temp="?"
for t in "$dev"/hwmon/hwmon*/temp1_input; do
  [[ -r $t ]] && { temp=$(($(cat "$t") / 1000)); break; }
done

vram="?"
if [[ -r $dev/mem_info_vram_used && -r $dev/mem_info_vram_total ]]; then
  used=$(($(cat "$dev/mem_info_vram_used") / 1048576))
  total=$(($(cat "$dev/mem_info_vram_total") / 1048576))
  vram=$(awk -v u="$used" -v t="$total" 'BEGIN { printf "%.1f / %.1f GiB", u/1024, t/1024 }')
fi

printf '{"text": "%s", "tooltip": "GPU  %s%%\\nTemp %s°C\\nVRAM %s"}\n' "$busy" "$busy" "$temp" "$vram"
