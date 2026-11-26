#!/usr/bin/env bash
# music-scroll.sh — waybar music module: "title — artist", scrolling back and forth.
# Replaces music.sh for the bar (same icons and fallbacks), but:
#   - title first, then artist (falls back to the player name, like music.sh)
#   - the icon stays put; only the text scrolls when it is longer than WIDTH
#   - no "…" cut at 42 characters: long titles scroll instead
#
# Runs forever and prints one line per step, so the waybar module needs no "interval".
#
#   WIDTH   visible characters of the text      (default 20)
#   STEP    seconds between scroll steps        (default 0.3)
#   PAUSE   steps to wait at each end           (default 5, about 1.5 s)

WIDTH=${WIDTH:-20}
STEP=${STEP:-0.3}
PAUSE=${PAUSE:-5}

# bash counts characters (not bytes) only in a UTF-8 locale; Greek titles need this
export LC_ALL=${LC_ALL:-C.UTF-8}

icon="" text="" offset=0 dir=1 wait=$PAUSE last_check=0

# one playerctl call per second: status, title, artist, player name
read_player() {
  local status title artist player
  IFS=$'\t' read -r status title artist player < <(
    playerctl metadata --format $'{{status}}\t{{title}}\t{{artist}}\t{{playerName}}' 2>/dev/null)

  case $status in
    Playing) icon="playing" ;;
    Paused)  icon="paused" ;;
    *)       icon="" new=""; return ;;
  esac
  if [[ -z $title ]]; then
    new=""
  elif [[ -n $artist ]]; then
    new="$title — $artist"
  else
    new="$title — $player"
  fi
}

# one JSON line for waybar: the text (escaped for JSON) and the state, which waybar shows as a dim "play"/"pause" label
out() { local t=${1//\\/\\\\}; t=${t//\"/\\\"}; printf '{"text": "%s", "alt": "%s"}\n' "$t" "$icon"; }

while true; do
  # ask for the song once a second, scroll in between
  now=$(date +%s)
  if ((now != last_check)); then
    last_check=$now
    read_player
    if [[ $new != "$text" ]]; then
      text=$new
      offset=0 dir=1 wait=$PAUSE    # new song: start from the beginning
    fi
  fi

  if [[ -z $text ]]; then
    echo '{"text": ""}'              # nothing playing: module hides itself
  else
    max=$((${#text} - WIDTH))       # how far the window can slide
    if ((max <= 0)); then
      out "$text"
    else
      out "${text:offset:WIDTH}"
      if ((wait > 0)); then
        ((wait--))                  # resting at one of the ends
      else
        ((offset += dir))
        if ((offset >= max || offset <= 0)); then
          ((offset >= max)) && offset=$max || offset=0
          dir=$((-dir))             # turn around, then rest
          wait=$PAUSE
        fi
      fi
    fi
  fi

  sleep "$STEP"
done
