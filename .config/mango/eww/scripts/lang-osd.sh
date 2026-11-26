#!/usr/bin/env bash
# Show a terminal-style eww OSD when the keyboard layout changes: all layouts, the current one bold, the others dim
# mango version of lang-osd.sh: listens to mmsg watch keyboardlayout; started by exec_once in the mango config
eww() { command eww -c "$HOME/.config/mango/eww" "$@"; }

# layout names in the order of xkb_rules_layout ("us,gr"), as mmsg reports them
layouts=("English (US)" "Greek")

first=1
stdbuf -oL mmsg watch keyboardlayout | while read -r line; do
  # the first line is the current state, not a change
  if ((first)); then first=0; continue; fi
  cur=$(jq -r .layout <<<"$line")

  # pango markup: current layout bold, the others at 45% alpha (like the dim icons in waybar)
  names=""
  for l in "${layouts[@]}"; do
    if [[ $l == "$cur" ]]; then part="<b>$l</b>"; else part="<span alpha='45%'>$l</span>"; fi
    names+="${names:+  }$part"
  done

  # show (or refresh) the OSD and close it 1.5 s after the last change, like volume.sh
  token=$(date +%s%N)
  eww update osd_text="lang  $names" osd_token="$token"
  if ! eww active-windows | grep -q "^osd"; then
    out=$("$HOME/.config/mango/scripts/focused-output" --eww)
    eww open osd ${out:+--screen "$out"} 2>/dev/null || eww open osd
  fi
  (sleep 1.5; [[ $(eww get osd_token) == "$token" ]] && eww close osd) >/dev/null 2>&1 &
done
