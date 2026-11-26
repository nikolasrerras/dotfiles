#!/usr/bin/env bash
# mango copy: every eww call goes to the mango eww config, not the niri one
eww() { command eww -c "$HOME/.config/mango/eww" "$@"; }
# Terminal-style month calendar for eww:  cal.sh today | next | prev
case $1 in
  next) off=$(( $(eww get cal_off) + 1 )) ;;
  prev) off=$(( $(eww get cal_off) - 1 )) ;;
  *)    off=0 ;;
esac

read -r m y title < <(date -d "$(date +%Y-%m-15) $off month" +'%-m %Y %B %Y')
colors="$HOME/.config/eww/colors.scss"
accent=$(grep -o '^\$accent: #[0-9A-Fa-f]*' "$colors" | cut -d' ' -f2)
muted=$(grep -o '^\$muted: #[0-9A-Fa-f]*' "$colors" | cut -d' ' -f2)

grid=$(cal -m "$m" "$y" | tail -n +2 | sed '/^\s*$/d')
head=$(sed -n 1p <<<"$grid")
body=$(sed -n '2,$p' <<<"$grid")

# highlight today (only when showing the current month)
if ((off == 0)); then
  d=$(date +%-d)
  body=$(sed -E "s/(^| )($d)( |$)/\1<span foreground='$accent'><b>\2<\/b><\/span>\3/" <<<"$body")
fi

text="<span foreground='$muted'>$head</span>"$'\n'"$body"
eww update cal_off="$off" cal_title="$(tr '[:upper:]' '[:lower:]' <<<"$title")" cal_text="$text"
