#!/usr/bin/env bash
# mango copy: every eww call goes to the mango eww config, not the niri one
eww() { command eww -c "$HOME/.config/mango/eww" "$@"; }
# audio.sh — data and actions for the eww audio popup (wpctl + pactl)
#
#   audio.sh                     print the state as JSON (volume, mute, mic, apps, outputs)
#   audio.sh set <0-100>         set the output volume
#   audio.sh mute                toggle output mute
#   audio.sh mic <0-100>         set the microphone volume
#   audio.sh mic-mute            toggle microphone mute
#   audio.sh app <id> <0-100>    set the volume of one app (pulse sink-input index)
#   audio.sh app-mute <id>       toggle mute of one app
#   audio.sh step <row> up|down  scroll on a row: set (output), mic, or app <id>
#   audio.sh sink <name>         switch the default output device
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

# apps playing sound right now, with a tree branch for the popup (├ for all but the last, └ for the last)
apps() {
  pactl -f json list sink-inputs 2>/dev/null | jq -c '
    [ .[] | {
        id: .index,
        name: ((.properties."application.name" // .properties."application.process.binary" // "app")
               | if test("webrtc"; "i") then "Discord" else . end
               | .[0:8]),
        vol: (.volume | to_entries[0].value.value_percent | rtrimstr("%") | tonumber),
        muted: .mute } ]
    | . as $a
    | [ range(0; length) as $i | $a[$i] + { branch: (if $i == ($a | length) - 1 then "└" else "├" end) } ]'
}

state() {
  local vol muted mic mic_muted default apps_json
  read -r vol muted < <(level "$sink")
  read -r mic mic_muted < <(level "$source")
  default=$(pactl get-default-sink 2>/dev/null)
  apps_json=$(apps)
  [[ -n $apps_json ]] || apps_json='[]'
  pactl -f json list sinks 2>/dev/null |
    jq -c --argjson vol "$vol" --argjson muted "$muted" \
          --argjson mic "$mic" --argjson mic_muted "$mic_muted" --arg default "$default" \
          --argjson apps "$apps_json" '
      { vol: $vol, muted: $muted, mic: $mic, mic_muted: $mic_muted, apps: $apps,
        sinks: [ .[] | { name, desc: .description, default: (.name == $default) } ] }'
}

# pactl lets an app go past 100%; keep it at 100 like the other rows
cap_app() {
  local v
  v=$(pactl -f json list sink-inputs 2>/dev/null | jq --argjson id "$1" \
      '.[] | select(.index == $id) | .volume | to_entries[0].value.value_percent | rtrimstr("%") | tonumber')
  [[ -n $v ]] && ((v > 100)) && pactl set-sink-input-volume "$1" 100%
}

refresh() { $EWW update audio="$(state)"; }

exec 9>/tmp/eww-audio.lock; flock 9
case "${1:-}" in
  "")       state ;;
  set)      wpctl set-volume -l 1.0 "$sink" "${2%.*}%"; refresh ;;
  step)
    d=+; [ "${!#}" = down ] && d=-   # the direction is always the last argument
    if [ "$2" = app ]; then
      pactl set-sink-input-volume "$3" "${d}5%"; [ "$d" = + ] && cap_app "$3"
    else
      t=$sink; [ "$2" = mic ] && t=$source
      wpctl set-volume -l 1.0 "$t" "5%$d"
    fi
    refresh ;;
  mute)     wpctl set-mute "$sink" toggle; refresh ;;
  mic)      wpctl set-volume -l 1.0 "$source" "${2%.*}%"; refresh ;;
  mic-mute) wpctl set-mute "$source" toggle; refresh ;;
  app)      pactl set-sink-input-volume "$2" "${3%.*}%"; refresh ;;
  app-mute) pactl set-sink-input-mute "$2" toggle; refresh ;;
  sink)     pactl set-default-sink "$2"; refresh ;;
  *)        sed -n '2,14p' "$0" | sed 's/^# \{0,1\}//'; exit 1 ;;
esac
