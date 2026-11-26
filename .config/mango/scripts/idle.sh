#!/usr/bin/env bash
# idle.sh — mango version of the niri swayidle.service: screens off after 30 min, suspend after 2 h
# Started by exec_once in the mango config
exec swayidle -w timeout 1800 "wlopm --off \"*\"" resume "wlopm --on \"*\"" timeout 7200 "systemctl suspend"
