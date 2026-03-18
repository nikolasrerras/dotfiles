#!/bin/bash

options=" Lock\n Sleep\n󰍃 Logout\n Restart\n Shutdown"

choice=$(echo -e "$options" | fuzzel --dmenu --prompt "Power Options ❯ " --lines 5)

case "$choice" in
*"Lock") loginctl lock-session ;;
*"Sleep") systemctl suspend ;;
*"Logout") niri msg action quit ;;
*"Restart") systemctl reboot ;;
*"Shutdown") systemctl poweroff ;;
esac
