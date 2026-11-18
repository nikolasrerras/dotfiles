#!/usr/bin/env bash
# Show the volume OSD on every volume or mute change of a sink: keys, waybar scroll, other apps
# Started by spawn-at-startup in niri config
pactl subscribe | grep --line-buffered "'change' on sink #" | while read -r _; do
  ~/.config/eww/scripts/volume.sh show
done
