#!/usr/bin/env bash
# idle.sh — mango version of the niri swayidle.service:
# lock after 30 min, screens off 30 s later, suspend after 2 h, and lock before every suspend
# Started by exec_once in the mango config
lock="$HOME/.config/mango/scripts/lock"
exec swayidle -w timeout 1800 "setsid -f $lock" timeout 1830 "wlopm --off \"*\"" resume "wlopm --on \"*\"" timeout 7200 "systemctl suspend" before-sleep "setsid -f $lock; sleep 1"
