#!/usr/bin/env bash
# Show a terminal-style eww OSD when the keyboard layout changes: all layouts, the current one bold, the others dim
# Listens to the niri event stream; started by spawn-at-startup in niri config
niri msg --json event-stream | while read -r line; do
  [[ $line == *KeyboardLayoutSwitched* ]] || continue
  idx=$(jq -r ".KeyboardLayoutSwitched.idx" <<<"$line")

  # pango markup: current layout bold, the others at 45% alpha (like the dim icons in waybar)
  names=$(niri msg --json keyboard-layouts | jq -r ".names | to_entries | map(if .key == $idx then \"<b>\" + .value + \"</b>\" else \"<span alpha='45%'>\" + .value + \"</span>\" end) | join(\"  \")")

  # show (or refresh) the OSD and close it 1.5 s after the last change, like volume.sh
  token=$(date +%s%N)
  eww update osd_text="lang  $names" osd_token="$token"
  if ! eww active-windows | grep -q "^osd"; then
    out=$(niri msg -j focused-output 2>/dev/null | jq -r .model)
    eww open osd --screen "$out"
  fi
  (sleep 1.5; [[ $(eww get osd_token) == "$token" ]] && eww close osd) >/dev/null 2>&1 &
done
