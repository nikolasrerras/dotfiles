#!/usr/bin/env bash
# Streams the current MPRIS track as JSON lines for eww (deflisten)

cache="${XDG_CACHE_HOME:-$HOME/.cache}/eww/art"
mkdir -p "$cache"

# album art: local file (browsers) or download it once (Spotify)
art_path() {
  local url="$1" f
  case "$url" in
    file://*)
      printf '%s' "${url#file://}" | sed 's/%20/ /g'
      ;;
    http://* | https://*)
      f="$cache/$(printf '%s' "$url" | md5sum | cut -d' ' -f1)"
      [[ -s $f ]] || curl -fsSL --max-time 5 -o "$f" "$url" 2>/dev/null
      [[ -s $f ]] && printf '%s' "$f"
      ;;
  esac
}

empty='{"status":"Stopped","title":"","artist":"","album":"","art":"","length":0}'
echo "$empty"

playerctl --follow metadata \
  --format $'{{status}}\t{{title}}\t{{artist}}\t{{album}}\t{{mpris:artUrl}}\t{{mpris:length}}' 2>/dev/null |
  while IFS=$'\t' read -r status title artist album url length; do
    if [[ -z $status && -z $title ]]; then
      echo "$empty"
      continue
    fi
    [[ $length =~ ^[0-9]+$ ]] || length=0
    jq -nc \
      --arg s "$status" --arg t "$title" --arg a "$artist" --arg al "$album" \
      --arg art "$(art_path "$url")" --argjson len "$((length / 1000000))" \
      '{status: $s, title: $t, artist: $a, album: $al, art: $art, length: $len}'
  done
