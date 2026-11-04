#!/usr/bin/env bash
# Toggle the media popup on the focused monitor
if eww active-windows | grep -q "^media"; then
  eww close media
  exit 0
fi
out=$(niri msg -j focused-output 2>/dev/null | jq -r .model)
eww open media --screen "$out"
setsid -f "$HOME/.config/eww/scripts/close-later.sh" >/dev/null 2>&1
