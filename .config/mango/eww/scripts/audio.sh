#!/usr/bin/env bash
# mango copy: every eww call goes to the mango eww config, not the niri one
eww() { command eww -c "$HOME/.config/mango/eww" "$@"; }
# audio.sh — data and actions for the eww audio popup (wpctl + pactl)
#
#   audio.sh                print the state as JSON (volume, mute, mic, outputs)
#   audio.sh set <0-100>    set the output volume
#   audio.sh mute           toggle output mute
#   audio.sh mic <0-100>    set the microphone volume
#   audio.sh mic-mute       toggle microphone mute
#   audio.sh sink <name>    switch the default output device
#
# Every action refreshes the popup right away.

sink=@DEFAULT_AUDIO_SINK@
source=@DEFAULT_AUDIO_SOURCE@
EWW="eww"

# "Volume: 0.60" or "Volume: 0.60 [MUTED]" -> "60 true|false"
level() {
  local _ vol muted
  read -r _ vol muted < <(wpctl get-volume "$1" 2>/dev/null)
  printf '%d %s\n' "$(awk -v v="${vol:-0}" 'BEGIN { printf "%d", v * 100 + 0.5 }')" \
    "$([[ -n $muted ]] && echo true || echo false)"
}

state() {
  local vol muted mic mic_muted default
  read -r vol muted < <(level "$sink")
  read -r mic mic_muted < <(level "$source")
  default=$(pactl get-default-sink 2>/dev/null)
  pactl -f json list sinks 2>/dev/null |
    jq -c --argjson vol "$vol" --argjson muted "$muted" \
          --argjson mic "$mic" --argjson mic_muted "$mic_muted" --arg default "$default" '
      { vol: $vol, muted: $muted, mic: $mic, mic_muted: $mic_muted,
        sinks: [ .[] | { name, desc: .description, default: (.name == $default) } ] }'
}

refresh() { $EWW update audio="$(state)"; }

exec 9>/tmp/eww-audio.lock; flock 9
case "${1:-}" in
  "")       state ;;
  set)      wpctl set-volume -l 1.0 "$sink" "${2%.*}%"; refresh ;;
  step)     t=$sink; [ "$2" = mic ] && t=$source; d=+; [ "$3" = down ] && d=-; wpctl set-volume -l 1.0 "$t" "5%$d"; refresh ;;
  mute)     wpctl set-mute "$sink" toggle; refresh ;;
  mic)      wpctl set-volume -l 1.0 "$source" "${2%.*}%"; refresh ;;
  mic-mute) wpctl set-mute "$source" toggle; refresh ;;
  sink)     pactl set-default-sink "$2"; refresh ;;
  *)        sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'; exit 1 ;;
esac
