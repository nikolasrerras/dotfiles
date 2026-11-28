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
# the per-process snapshots (p1, p2) use the same 0.4 s, for the top list at the end
p1=$(cat /proc/[0-9]*/stat 2>/dev/null)
read -r _ a b c i w q s _ < /proc/stat; t1=$((a+b+c+i+w+q+s)); i1=$((i+w))
sleep 0.4
read -r _ a b c i w q s _ < /proc/stat; t2=$((a+b+c+i+w+q+s)); i2=$((i+w))
p2=$(cat /proc/[0-9]*/stat 2>/dev/null)
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
mib() { awk -v b="$1" 'BEGIN { if (b >= 1073741824) printf "%.1fG", b / 1073741824; else printf "%dM", b / 1048576 }'; }   # app memory: M below 1G

# the 3 apps using the most cpu right now, with their memory
# cpu is the share of the whole processor over the same 0.4 s as the cpu line, so it adds up with it
# processes are grouped by executable, so all of zen's or discord's processes count as one app
top_apps() {
  awk -v total="$((t2 - t1))" -v page="$(getconf PAGESIZE)" '
    function parse(line,   o, c, k, f) {   # sets PID, TICKS, RSS from one /proc/<pid>/stat line
      o = index(line, "(")
      for (k = length(line); k > o; k--) if (substr(line, k, 1) == ")") { c = k; break }
      PID = substr(line, 1, o - 2) + 0
      split(substr(line, c + 2), f, " ")
      TICKS = f[12] + f[13]; RSS = f[22] * page
    }
    function short(b) {   # nicer names for a few multi-process apps
      sub(/-bin$/, "", b)
      if (b == "steamwebhelper") b = "steam"
      if (b == "Discord" || b == "DiscordCanary") b = "discord"
      return substr(b, 1, 12)
    }
    FNR == 1 { file++ }
    file == 1 {   # ps: pid and the executable path
      pid = $1; $1 = ""; sub(/^ /, "")
      n = split($1, parts, /[\/\\]/); name[pid] = short(parts[n])
      next
    }
    file == 2 { parse($0); before[PID] = TICKS; next }
    file == 3 {
      parse($0)
      if (!(PID in name)) next
      app = name[PID]
      if (PID in before) cpu[app] += TICKS - before[PID]
      mem[app] += RSS
    }
    END {
      for (app in cpu) if (cpu[app] > 0) printf "%s %.1f %d\n", app, (total > 0 ? 100 * cpu[app] / total : 0), mem[app]
    }' <(ps -eo pid=,args=) <(printf '%s\n' "$p1") <(printf '%s\n' "$p2") |
    sort -k2,2nr | head -n 3
}

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

# top apps by cpu, under a section line like the audio popup
printf '\n'
printf "<span foreground='%s'>── top ──────────────────────────────────</span>\n" "$muted"
top_apps | while read -r app pct bytes; do
  app=${app//&/&amp;}; app=${app//</&lt;}; app=${app//>/&gt;}
  printf '%-12s %5s%%  %6s\n' "$app" "$pct" "$(mib "$bytes")"
done
