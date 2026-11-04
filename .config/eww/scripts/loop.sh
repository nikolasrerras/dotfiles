#!/usr/bin/env bash
# Repeat: none -> playlist -> track -> none
case "$(playerctl loop 2>/dev/null)" in
  None)     playerctl loop Playlist ;;
  Playlist) playerctl loop Track ;;
  *)        playerctl loop None ;;
esac
