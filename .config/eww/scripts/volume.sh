#!/usr/bin/env bash
# Volume control with a terminal-style eww OSD:  vol ████████████░░░░░░░░  60%
# usage: volume.sh up | down | mute

step=5
sink=@DEFAULT_AUDIO_SINK@

case "$1" in
  up)   wpctl set-mute "$sink" 0; wpctl set-volume -l 1.0 "$sink" "${step}%+" ;;
  down) wpctl set-volume "$sink" "${step}%-" ;;
  mute) wpctl set-mute "$sink" toggle ;;
esac

# "Volume: 0.60" or "Volume: 0.60 [MUTED]"
read -r _ vol muted < <(wpctl get-volume "$sink")
pct=$(awk -v v="$vol" 'BEGIN { printf "%d", v * 100 + 0.5 }')

width=20
filled=$((pct * width / 100))
((filled > width)) && filled=$width
full=$(printf '%*s' "$filled" '');               full=${full// /█}
empty=$(printf '%*s' "$((width - filled))" ''); empty=${empty// /░}

label="vol "
[[ -n $muted ]] && label="mute"
text=$(printf '%s %s%s %3d%%' "$label" "$full" "$empty" "$pct")

# show (or refresh) the OSD and close it 1.5 s after the last change
token=$(date +%s%N)
eww update osd_text="$text" osd_token="$token"
if ! eww active-windows | grep -q '^osd'; then
  out=$(niri msg -j focused-output 2>/dev/null | jq -r .model)
  eww open osd --screen "$out"
fi
(sleep 1.5; [[ $(eww get osd_token) == "$token" ]] && eww close osd) >/dev/null 2>&1 &
