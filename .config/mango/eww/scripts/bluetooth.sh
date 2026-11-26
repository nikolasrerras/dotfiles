#!/usr/bin/env bash
# mango copy: every eww call goes to the mango eww config, not the niri one
eww() { command eww -c "$HOME/.config/mango/eww" "$@"; }
# bluetooth.sh — data and actions for the eww bluetooth popup (bluetoothctl)
#
#   bluetooth.sh                 print the state as JSON (power, paired devices)
#   bluetooth.sh power           turn bluetooth on / off
#   bluetooth.sh toggle <mac>    connect a paired device, or disconnect it if connected
#
# Pairing new devices needs prompts, so that stays in bluetui (button in the popup).

strip() { sed 's/\x1b\[[0-9;]*m//g'; }   # in case bluetoothctl prints colours

icon_for() {
  case $1 in
    audio-headset|audio-headphones) echo "󰋋" ;;
    audio-card)                     echo "󰓃" ;;
    input-mouse)                    echo "󰍽" ;;
    input-keyboard)                 echo "󰌌" ;;
    input-gaming)                   echo "󰊴" ;;
    phone)                          echo "󰏲" ;;
    *)                              echo "󰂯" ;;
  esac
}

state() {
  local powered=false mac name info connected battery icon
  bluetoothctl show 2>/dev/null | strip | grep -q 'Powered: yes' && powered=true

  # one tab-separated line per paired device, turned into JSON by jq
  bluetoothctl devices Paired 2>/dev/null | strip | while read -r _ mac name; do
    info=$(bluetoothctl info "$mac" 2>/dev/null | strip)
    connected=$(grep -q 'Connected: yes' <<<"$info" && echo true || echo false)
    battery=$(sed -n 's/.*Battery Percentage:.*(\([0-9]*\)).*/\1/p' <<<"$info")
    icon=$(icon_for "$(sed -n 's/^\s*Icon: //p' <<<"$info")")
    printf '%s\t%s\t%s\t%s\t%s\n' "$mac" "$name" "$connected" "${battery:-}" "$icon"
  done | jq -Rsc --argjson powered "$powered" '
    { powered: $powered,
      devices: [ split("\n")[] | select(length > 0) | split("\t")
                 | { mac: .[0], name: .[1], connected: (.[2] == "true"),
                     battery: .[3], icon: .[4] } ]
               | sort_by(.connected | not) } | .connected = ([.devices[] | select(.connected)] | length)'
}

refresh() { eww update bluetooth="$(state)"; }

case "${1:-}" in
  "")     state ;;
  power)
    if bluetoothctl show | strip | grep -q 'Powered: yes'; then
      bluetoothctl power off >/dev/null
    else
      bluetoothctl power on >/dev/null
    fi
    sleep 1; refresh ;;
  toggle)
    if bluetoothctl info "$2" | strip | grep -q 'Connected: yes'; then
      bluetoothctl disconnect "$2" >/dev/null
    else
      bluetoothctl connect "$2" >/dev/null
    fi
    refresh ;;
  disconnect)
    # disconnect every connected device
    bluetoothctl devices Connected | strip | while read -r _ mac _; do
      bluetoothctl disconnect "$mac" >/dev/null
    done
    refresh ;;
  *) sed -n '2,8p' "$0" | sed 's/^# \{0,1\}//'; exit 1 ;;
esac
