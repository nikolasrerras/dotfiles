#!/usr/bin/env bash
# Close eww popups when the active tag changes (mango version of popup-autoclose.sh)
# Started by exec_once in the mango config
eww() { command eww -c "$HOME/.config/mango/eww" "$@"; }
prev=""
stdbuf -oL mmsg watch all-tags | while read -r line; do
  # only the active tags matter, not window counts
  cur=$(jq -c "[.all_tags[] | {monitor, active: [.tags[] | select(.is_active) | .index]}]" <<<"$line")
  if [[ -n $prev && $cur != "$prev" ]] && eww active-windows | grep -qv "^osd"; then
    "$HOME/.config/mango/eww/scripts/popup.sh" close
  fi
  prev=$cur
done
