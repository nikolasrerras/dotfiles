#!/usr/bin/env bash
# wifi.sh — data and actions for the eww wifi popup (iwd / iwctl, same backend as impala)
#
#   wifi.sh                  print the state as JSON (power, connection, networks)
#   wifi.sh scan             scan for networks, refresh the popup when done
#   wifi.sh power            turn wifi on / off
#   wifi.sh connect <b64>    connect to a network (name is base64, so any name is safe)
#   wifi.sh disconnect       disconnect
#
# Networks that need a password and are not saved yet open impala instead,
# since a password cannot be typed into the popup.

IFACE=${IFACE:-$(ls /sys/class/net 2>/dev/null | grep -m1 '^wl')}
IMPALA="kitty --class=com.floating.tui -o remember_window_size=no -o initial_window_width=90c -o initial_window_height=30c -o window_padding_width=0 impala"

strip() { sed 's/\x1b\[[0-9;]*m//g'; }   # iwctl prints colours

state() {
  DEVICE=$(iwctl device "$IFACE" show 2>/dev/null | strip) \
  STATION=$(iwctl station "$IFACE" show 2>/dev/null | strip) \
  NETWORKS=$(iwctl station "$IFACE" get-networks 2>/dev/null | strip) \
  KNOWN=$(iwctl known-networks list 2>/dev/null | strip) \
  IP=$(ip -4 -o addr show "$IFACE" 2>/dev/null | awk '{print $4}' | head -n1) \
  python3 - <<'PY'
import base64, json, os, re

def field(text, name):
    # rows look like "      *     Powered    on" (the * marks settable properties)
    m = re.search(rf"^\s*\*?\s*{name}\s{{2,}}(.+?)\s*$", text, re.M)
    return m.group(1) if m else ""

# "  >   Name with spaces        psk        ****"
row = re.compile(r"^\s*(>)?\s*(.+?)\s{2,}(psk|open|8021x|wep)\s+(\*+)\s*$")
known = {m.group(1) for m in (re.match(r"^\s{2,}(.+?)\s{2,}(psk|open|8021x|wep)\s", l)
                              for l in os.environ["KNOWN"].splitlines()) if m}
icons = ["󰤯", "󰤟", "󰤢", "󰤥", "󰤨"]

nets = []
for line in os.environ["NETWORKS"].splitlines():
    m = row.match(line)
    if not m:
        continue
    current, name, security, stars = m.groups()
    nets.append({
        "name": name,
        "b64": base64.b64encode(name.encode()).decode(),
        "secure": security != "open",
        "known": name in known,
        "connected": bool(current),
        "icon": icons[min(len(stars), 4)],
    })

state = field(os.environ["STATION"], "State")
print(json.dumps({
    "powered": field(os.environ["DEVICE"], "Powered") == "on",
    "state": state or "off",
    "ssid": field(os.environ["STATION"], "Connected network"),
    "ip": os.environ["IP"],
    "networks": nets[:8],
}, ensure_ascii=False))
PY
}

refresh() { eww update wifi="$(state)"; }

case "${1:-}" in
  "")    state ;;
  scan)  iwctl station "$IFACE" scan 2>/dev/null; sleep 3; refresh ;;
  power)
    if iwctl device "$IFACE" show | strip | grep -qE '^\s*\*?\s*Powered\s+on'; then
      iwctl device "$IFACE" set-property Powered off
    else
      iwctl device "$IFACE" set-property Powered on
    fi
    sleep 1; refresh ;;
  connect)
    name=$(printf '%s' "$2" | base64 -d)
    net=$(state | jq -c --arg n "$name" '.networks[] | select(.name == $n)')
    if [[ $(jq -r '.known or (.secure | not)' <<<"$net") == true ]]; then
      iwctl station "$IFACE" connect "$name"
      sleep 1; refresh
    else
      # new network with a password: let impala ask for it
      eww close wifi
      setsid -f $IMPALA >/dev/null 2>&1
    fi ;;
  disconnect) iwctl station "$IFACE" disconnect; sleep 1; refresh ;;
  *) sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'; exit 1 ;;
esac
