#!/usr/bin/env bash
# Close the media popup 1 s after the pointer leaves it, unless it comes back
token=$(date +%s%N)
eww update media_inside=false media_token="$token"
sleep 1
[[ $(eww get media_inside) == false && $(eww get media_token) == "$token" ]] && eww close media
