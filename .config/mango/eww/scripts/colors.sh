#!/usr/bin/env bash
# mango copy: every eww call goes to the mango eww config, not the niri one
eww() { command eww -c "$HOME/.config/mango/eww" "$@"; }
# Writes eww colors from the theme system (wallust palette + waybar accent)
source "$HOME/.cache/wallust/colors.sh" || exit 1
accent=$(grep -o '#[0-9A-Fa-f]\{6\}' "$HOME/.config/waybar/accent.css" 2>/dev/null | head -1)
printf '$bg: %s;\n$fg: %s;\n$accent: %s;\n$muted: %s;\n' \
  "$background" "$foreground" "${accent:-$color4}" "$color8" >"$HOME/.config/eww/colors.scss"
