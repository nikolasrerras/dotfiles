#!/usr/bin/env bash
# games.sh — move each newly opened Steam game to the first empty tag of the main monitor and follow it
# (mango only; started by exec_once in the mango config)
MAIN=DP-1
seen=" "
first=1
stdbuf -oL mmsg watch all-clients | while read -r line; do
  for id in $(jq -r ".clients[] | select((.appid // \"\") | test(\"^steam_app_\")) | .id" <<<"$line" 2>/dev/null); do
    [[ $seen == *" $id "* ]] && continue
    seen+="$id "
    ((first)) && continue  # games already open when the script starts stay where they are
    # tags of the main monitor that hold other windows
    used=$(jq -r --arg m "$MAIN" --argjson id "$id" "[.clients[] | select(.monitor == \$m and .id != \$id) | .tags[]] | unique | .[]" <<<"$line")
    free=""
    for t in 1 2 3 4 5 6 7 8 9; do grep -qx "$t" <<<"$used" || { free=$t; break; }; done
    [[ -n $free ]] || continue
    mmsg dispatch tagmon,$MAIN client,$id
    mmsg dispatch tag,$free,0 client,$id
    mmsg dispatch focusmon,$MAIN
    mmsg dispatch view,$free,0
  done
  first=0
done
