#!/usr/bin/env bash
# mango copy: every eww call goes to the mango eww config, not the niri one
eww() { command eww -c "$HOME/.config/mango/eww" "$@"; }
# System overview for eww (pango markup, character bars)
colors="$HOME/.config/eww/colors.scss"
accent=$(grep -o '^\$accent: #[0-9A-Fa-f]*' "$colors" | cut -d' ' -f2)
muted=$(grep -o '^\$muted: #[0-9A-Fa-f]*' "$colors" | cut -d' ' -f2)
W=16

bar() {   # bar <percent>
  local p=$1 f
  ((p > 100)) && p=100
  f=$((p * W / 100))
  local full empty
  full=$(printf '%*s' "$f" ''); full=${full// /█}
  empty=$(printf '%*s' "$((W - f))" ''); empty=${empty// /░}
  printf "<span foreground='%s'>%s</span><span foreground='%s'>%s</span>" "$accent" "$full" "$muted" "$empty"
}
key() { printf "<span foreground='%s'>%-6s</span>" "$muted" "$1"; }

# cpu usage (0.4 s sample) + temperature
read -r _ a b c i w q s _ < /proc/stat; t1=$((a+b+c+i+w+q+s)); i1=$((i+w))
sleep 0.4
read -r _ a b c i w q s _ < /proc/stat; t2=$((a+b+c+i+w+q+s)); i2=$((i+w))
cpu=$(( (t2-t1) > 0 ? 100 * ((t2-t1) - (i2-i1)) / (t2-t1) : 0 ))
ctemp="?"
for h in /sys/class/hwmon/hwmon*; do
  [[ $(cat "$h/name" 2>/dev/null) == coretemp ]] && { ctemp=$(( $(cat "$h/temp1_input") / 1000 )); break; }
done

# gpu (amdgpu)
gpu=0 gtemp="?" vu=0 vt=1
for d in /sys/class/drm/card*/device; do
  if [[ -r $d/gpu_busy_percent ]]; then
    gpu=$(cat "$d/gpu_busy_percent")
    for t in "$d"/hwmon/hwmon*/temp1_input; do [[ -r $t ]] && gtemp=$(( $(cat "$t") / 1000 )); done
    vu=$(cat "$d/mem_info_vram_used" 2>/dev/null || echo 0)
    vt=$(cat "$d/mem_info_vram_total" 2>/dev/null || echo 1)
    break
  fi
done

# memory
read -r mt ma < <(awk '/^MemTotal/{t=$2} /^MemAvailable/{a=$2} END{print t, a}' /proc/meminfo)
mu=$((mt - ma))

gib() { awk -v b="$1" 'BEGIN { if (b >= 1099511627776) printf "%.1fT", b / 1099511627776; else printf "%.1fG", b / 1073741824 }'; }

printf '%s%s %3d%%  %s°C\n' "$(key cpu)" "$(bar "$cpu")" "$cpu" "$ctemp"
printf '%s%s %3d%%  %s°C\n' "$(key gpu)" "$(bar "$gpu")" "$gpu" "$gtemp"
printf '%s%s %s / %s\n' "$(key vram)" "$(bar $((vu * 100 / vt)))" "$(gib "$vu")" "$(gib "$vt")"
printf '%s%s %s / %s\n' "$(key mem)" "$(bar $((mu * 100 / mt)))" "$(gib $((mu * 1024)))" "$(gib $((mt * 1024)))"
printf '\n'
df -B1 --output=target,used,size / /mnt/ssd /mnt/hdd 2>/dev/null | tail -n +2 |
  while read -r target used size; do
    name=${target##*/}; [[ -z $name ]] && name="/"
    printf '%s%s %s / %s\n' "$(key "$name")" "$(bar $((used * 100 / size)))" "$(gib "$used")" "$(gib "$size")"
  done
