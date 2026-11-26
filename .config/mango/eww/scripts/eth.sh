#!/usr/bin/env bash
# eth.sh — wired connection for the eww wifi popup: interface, ip, gateway, link speed, live down/up
# Polled every second by eww, only while the wifi popup is open (wifi_open)

# bytes -> short human string
human() {
  local b=$1
  if (( b >= 1073741824 )); then echo "$((b / 1073741824)).$((b % 1073741824 * 10 / 1073741824))G"
  elif (( b >= 1048576 )); then echo "$((b / 1048576)).$((b % 1048576 * 10 / 1048576))M"
  elif (( b >= 1024 )); then echo "$((b / 1024))K"
  else echo "${b}B"; fi
}

# first wired interface that is up: a real device without a wireless directory
dev=""
for d in /sys/class/net/*; do
  [[ -e $d/device && ! -d $d/wireless && $(<"$d/operstate") == up ]] && { dev=${d##*/}; break; }
done
if [[ -z $dev ]]; then
  echo '{"connected":false,"dev":"","ip":"","gw":"","link":"","down":"","up":"","rx":"","tx":""}'
  exit 0
fi

ip=$(ip -4 -o addr show "$dev" 2>/dev/null | awk '{print $4}' | head -n1)
gw=$(ip route show default dev "$dev" 2>/dev/null | awk '{print $3; exit}')
link="$(cat "/sys/class/net/$dev/speed" 2>/dev/null) Mb/s"
rx=$(<"/sys/class/net/$dev/statistics/rx_bytes"); tx=$(<"/sys/class/net/$dev/statistics/tx_bytes"); now=$(date +%s%N)

# speed = bytes since the previous poll / time since the previous poll
state="/tmp/eww-eth-$dev"; down=0; up=0
if [[ -r $state ]]; then
  read -r prx ptx pnow <"$state"
  ms=$(( (now - pnow) / 1000000 ))
  if (( ms > 0 && ms < 10000 )); then down=$(( (rx - prx) * 1000 / ms )); up=$(( (tx - ptx) * 1000 / ms )); fi
  (( down < 0 )) && down=0; (( up < 0 )) && up=0
fi
echo "$rx $tx $now" >"$state"

jq -nc --arg dev "$dev" --arg ip "${ip:--}" --arg gw "${gw:--}" --arg link "$link" --arg down "$(human "$down")/s" --arg up "$(human "$up")/s" --arg rx "$(human "$rx")" --arg tx "$(human "$tx")" '{connected: true, dev: $dev, ip: $ip, gw: $gw, link: $link, down: $down, up: $up, rx: $rx, tx: $tx}'
