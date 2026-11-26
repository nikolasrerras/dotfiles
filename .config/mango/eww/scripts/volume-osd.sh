#!/usr/bin/env bash
# mango copy: every eww call goes to the mango eww config, not the niri one
eww() { command eww -c "$HOME/.config/mango/eww" "$@"; }
# Show the volume OSD on every volume or mute change of the default sink: keys, waybar scroll, other apps
# Started by spawn-at-startup in niri config
# PipeWire also sends "change" when a sink starts or stops playing, so compare with the last state first
prev=$(wpctl get-volume @DEFAULT_AUDIO_SINK@)
pactl subscribe | grep --line-buffered "'change' on sink #" | while read -r _; do
  cur=$(wpctl get-volume @DEFAULT_AUDIO_SINK@)
  if [[ -z $prev || $SECONDS -lt 5 ]]; then prev=$cur; continue; fi  # login: PipeWire is still starting, just remember the state
  [[ $cur == "$prev" ]] && continue
  prev=$cur
  ~/.config/mango/eww/scripts/volume.sh show
done
