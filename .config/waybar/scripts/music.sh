#!/usr/bin/env bash

status="$(playerctl status 2>/dev/null)" || exit 0

case "$status" in
    Playing) icon="󰎈" ;;
    Paused)  icon="󰏤" ;;
    *) exit 0 ;;
esac

artist="$(playerctl metadata artist 2>/dev/null)"
title="$(playerctl metadata title 2>/dev/null)"
player="$(playerctl metadata --format "{{ playerName }}" 2>/dev/null)"

[[ -z "$title" ]] && exit 0

if [[ -n "$artist" ]]; then
    text="$artist — $title"
else
    text="$player — $title"
fi

max=42; (( ${#text} > max )) && text="${text:0:max-1}…"
printf "%s  %s\n" "$icon" "$text"
