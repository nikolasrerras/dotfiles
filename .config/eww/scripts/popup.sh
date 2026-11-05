#!/usr/bin/env bash
# Toggle an eww popup on the focused monitor:  popup.sh <window>
# Closes by itself 1 s after the pointer leaves it (or if it is never entered).
win=${1:-media}
dir="$HOME/.config/eww/scripts"

if eww active-windows | grep -q "^$win"; then
  eww close "$win"
  exit 0
fi

case $win in
  calendar) "$dir/cal.sh" today ;;
  system)   eww update sys_text="$("$dir/sys.sh")" ;;
esac

out=$(niri msg -j focused-output 2>/dev/null | jq -r .model)
eww open "$win" --screen "$out"
setsid -f "$dir/close-later.sh" "$win" >/dev/null 2>&1
