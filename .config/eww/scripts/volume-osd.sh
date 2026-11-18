#!/usr/bin/env bash
# Show the volume OSD on every volume or mute change of the default sink: keys, waybar scroll, other apps
# Started by spawn-at-startup in niri config
# PipeWire also sends "change" when a sink starts or stops playing, so compare with the last state first
prev=$(wpctl get-volume @DEFAULT_AUDIO_SINK@)
pactl subscribe | grep --line-buffered "'change' on sink #" | while read -r _; do
  cur=$(wpctl get-volume @DEFAULT_AUDIO_SINK@)
  [[ $cur == "$prev" ]] && continue
  prev=$cur
  ~/.config/eww/scripts/volume.sh show
done
