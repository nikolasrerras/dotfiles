#!/usr/bin/env bash
# Network status for waybar (mango copy of ~/.config/waybar/scripts/wifi.sh):
# ethernet when a cable is connected, otherwise the Wi-Fi signal from NetworkManager

eth=$(nmcli -t -f DEVICE,TYPE,STATE device 2>/dev/null | awk -F: '$2 == "ethernet" && $3 == "connected" {print $1; exit}')
if [[ -n $eth ]]; then
  ip=$(nmcli -g IP4.ADDRESS device show "$eth" 2>/dev/null | head -1)
  jq -nc --arg dev "$eth" --arg ip "${ip:-no address}" '{text: "eth", alt: "ethernet", class: "ethernet", tooltip: "\($dev)\n\($ip)"}'
  exit 0
fi

line=$(nmcli -t -f IN-USE,SIGNAL,SSID,FREQ device wifi list --rescan no 2>/dev/null | grep '^\*' | head -1)
if [[ -z $line ]]; then
  jq -nc '{text: "off", alt: "disconnected", class: "disconnected", tooltip: "Disconnected"}'
  exit 0
fi

IFS=: read -r _ signal ssid freq <<<"$line"
# five signal levels, matching the five wifi icons
level=$(( signal * 5 / 101 ))
jq -nc --arg ssid "$ssid" --arg freq "$freq" --argjson s "$signal" --argjson l "$level" '{text: "\($s)%", alt: "wifi-\($l)", class: "connected", tooltip: "\($ssid)\nSignal \($s)%\n\($freq)"}'
