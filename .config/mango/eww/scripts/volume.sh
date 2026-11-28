#!/usr/bin/env bash
# mango copy: every eww call goes to the mango eww config, not the niri one
eww() { command eww -c "$HOME/.config/mango/eww" "$@"; }
# Volume control with a terminal-style eww OSD:  vol ████████████░░░░░░░░  60%
# usage: volume.sh up | down | mute | micmute

step=5
sink=@DEFAULT_AUDIO_SINK@

case "$1" in
  up)   wpctl set-mute "$sink" 0; wpctl set-volume -l 1.0 "$sink" "${step}%+" ;;
  down) wpctl set-volume "$sink" "${step}%-" ;;
  mute) wpctl set-mute "$sink" toggle ;;
  micmute) wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle; set -- show mic ;;  # the mic mute key shows the same OSD
esac
[[ $1 == show ]] || exit 0  # the OSD itself is shown by volume-osd.sh, which listens for every volume change
if eww active-windows | grep -q "^audio"; then eww update audio="$(~/.config/mango/eww/scripts/audio.sh)"; exit 0; fi  # audio popup open: refresh it instead of showing the OSD

label=vol; [[ ${2:-} == mic ]] && { label=mic; sink=@DEFAULT_AUDIO_SOURCE@; }  # micmute: the same OSD for the default source
# "Volume: 0.60" or "Volume: 0.60 [MUTED]"
read -r _ vol muted < <(wpctl get-volume "$sink")
pct=$(awk -v v="$vol" 'BEGIN { printf "%d", v * 100 + 0.5 }')

width=20
filled=$((pct * width / 100))
((filled > width)) && filled=$width
full=$(printf '%*s' "$filled" '');               full=${full// /█}
empty=$(printf '%*s' "$((width - filled))" ''); empty=${empty// /░}

is_muted=false
if [[ -n $muted ]]; then
  # muted: empty bar and the word muted instead of the percentage
  is_muted=true
  empty=$(printf '%*s' "$width" ''); empty=${empty// /░}
  text=$(printf '%s  %s muted' "$label" "$empty")
else
  text=$(printf '%s  %s%s %3d%%' "$label" "$full" "$empty" "$pct")
fi

# show (or refresh) the OSD and close it 1.5 s after the last change
token=$(date +%s%N)
eww update osd_text="$text" osd_token="$token"
if ! eww active-windows | grep -q '^osd'; then
  out=$("$HOME/.config/mango/scripts/focused-output" --eww)
  eww open osd ${out:+--screen "$out"} 2>/dev/null || eww open osd
fi
(sleep 1.5; [[ $(eww get osd_token) == "$token" ]] && eww close osd) >/dev/null 2>&1 &
