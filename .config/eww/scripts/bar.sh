#!/usr/bin/env bash
# Print playback progress as JSON for the media popup: times, length and filled cells of the 30-cell bar
pos=$(playerctl position 2>/dev/null); pos=${pos%.*}; pos=${pos:-0}
len=$(playerctl metadata mpris:length 2>/dev/null); len=$(( ${len:-0} / 1000000 ))
filled=0; [ "$len" -gt 0 ] && filled=$(( pos * 30 / len ))
printf "{\"pos\":\"%02d:%02d\",\"len\":\"%02d:%02d\",\"lensec\":%d,\"filled\":%d}\n" $((pos / 60)) $((pos % 60)) $((len / 60)) $((len % 60)) "$len" "$filled"
