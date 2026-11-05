#!/usr/bin/env bash
# Close an eww popup 1 s after the pointer leaves it, unless it comes back
win=${1:-media}
token=$(date +%s%N)
eww update "${win}_inside=false" "${win}_token=$token"
sleep 1
[[ $(eww get "${win}_inside") == false && $(eww get "${win}_token") == "$token" ]] && eww close "$win"
