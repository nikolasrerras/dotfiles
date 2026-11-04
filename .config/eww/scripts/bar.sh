#!/usr/bin/env bash
# Text progress bar for the eww media popup:  01:23 ████████░░░░░░░░ 03:45
width=${1:-30}

pos=$(playerctl position 2>/dev/null | cut -d. -f1)
len=$(playerctl metadata mpris:length 2>/dev/null)
[[ $pos =~ ^[0-9]+$ ]] || pos=0
[[ $len =~ ^[0-9]+$ ]] || len=0
len=$((len / 1000000))

filled=0
((len > 0)) && filled=$((pos * width / len))
((filled > width)) && filled=$width

full=$(printf '%*s' "$filled" '');           full=${full// /█}
empty=$(printf '%*s' "$((width - filled))" ''); empty=${empty// /░}

fmt() { printf '%02d:%02d' $(($1 / 60)) $(($1 % 60)); }
echo "$(fmt "$pos") $full$empty $(fmt "$len")"
