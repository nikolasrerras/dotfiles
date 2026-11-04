#!/usr/bin/env bash
# CPU usage + package temperature for waybar (JSON output)

sample() { read -r _ u n s i w q sq _ < /proc/stat; idle=$((i + w)); total=$((u + n + s + i + w + q + sq)); }

sample; idle1=$idle; total1=$total
sleep 0.5
sample; idle2=$idle; total2=$total

dt=$((total2 - total1))
usage=0
((dt > 0)) && usage=$((100 * (dt - (idle2 - idle1)) / dt))

temp="?"
for h in /sys/class/hwmon/hwmon*; do
  if [[ $(cat "$h/name" 2>/dev/null) == coretemp ]]; then
    temp=$(($(cat "$h/temp1_input") / 1000))
    break
  fi
done

printf '{"text": "%s", "tooltip": "CPU  %s%%\\nTemp %s°C"}\n' "$usage" "$usage" "$temp"
