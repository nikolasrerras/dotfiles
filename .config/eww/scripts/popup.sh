#!/usr/bin/env bash
# Toggle an eww popup on the focused monitor:  popup.sh <window>
# Closes on a second click on its module, or on a click outside it (backdrop window).
win=${1:-media}
dir="$HOME/.config/eww/scripts"
if [[ $win == close ]]; then for w in $(eww active-windows | cut -d: -f1); do [[ $w == osd ]] || eww close "$w"; done; eww update wifi_open=false; exit 0; fi  # close every popup (used by the backdrop)

if eww active-windows | grep -q "^$win"; then
  eww close "$win" backdrop; eww update wifi_open=false
  exit 0
fi

eww update wifi_open=false  # the wifi popup sets it back to true below
case $win in
  calendar) "$dir/cal.sh" today ;;
  system)   eww update sys_text="$("$dir/sys.sh")" ;;
  power)    eww update power_confirm="" \
              power_uptime="$(awk '{ s = int($1); printf "%dh %dm", s / 3600, (s % 3600) / 60 }' /proc/uptime)" ;;
  audio)    eww update audio="$("$dir/audio.sh")" ;;
  wifi)     eww update wifi="$("$dir/wifi.sh")" wifi_open=true; setsid -f "$dir/wifi.sh" scan >/dev/null 2>&1 ;;
  bluetooth) eww update bluetooth="$("$dir/bluetooth.sh")" ;;
esac

for w in $(eww active-windows | cut -d: -f1); do [[ $w == osd ]] || eww close "$w"; done  # one popup at a time
out=$(niri msg -j focused-output 2>/dev/null | jq -r .model)
eww open "$win" --screen "$out"
eww open backdrop --screen "$out"  # transparent layer behind the popup: a click outside closes it
