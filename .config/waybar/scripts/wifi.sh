#!/usr/bin/env bash
# Wi-Fi signal for waybar, taken from NetworkManager
# (waybar's own network module reports a wrong percentage with iwd)

line=$(nmcli -t -f IN-USE,SIGNAL,SSID,FREQ device wifi list --rescan no 2>/dev/null | grep '^\*' | head -1)

if [[ -z $line ]]; then
  echo '{"text": "", "percentage": 0, "class": "disconnected", "tooltip": "Disconnected"}'
  exit 0
fi

IFS=: read -r _ signal ssid freq <<<"$line"
ssid=${ssid//\"/\\\"}

printf '{"text": "", "percentage": %d, "class": "connected", "tooltip": "%s\\nSignal %d%%\\n%s"}\n' \
  "$signal" "$ssid" "$signal" "$freq"
