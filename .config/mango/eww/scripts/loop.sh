#!/usr/bin/env bash
# mango copy: every eww call goes to the mango eww config, not the niri one
eww() { command eww -c "$HOME/.config/mango/eww" "$@"; }
# Repeat: none -> playlist -> track -> none
case "$(playerctl loop 2>/dev/null)" in
  None)     playerctl loop Playlist ;;
  Playlist) playerctl loop Track ;;
  *)        playerctl loop None ;;
esac
