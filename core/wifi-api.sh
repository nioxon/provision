#!/bin/bash
set -euo pipefail

ACTION=${1:-status}
SSID=${2:-}
PASS=${3:-}

# Force stdout to be JSON
exec 3>&1

WIFI_IF=$(iw dev 2>/dev/null | awk '$1=="Interface"{print $2}' | head -n1 || true)

if [[ -z "$WIFI_IF" ]]; then
  printf '{"status":"error","message":"No WiFi adapter detected"}\n' >&3
  exit 0
fi

if [[ "$ACTION" == "status" ]]; then
  STATUS=$(nmcli -t -f DEVICE,STATE dev | grep "^$WIFI_IF" | cut -d: -f2 || true)
  if [[ "$STATUS" == "connected" ]]; then
     CURRENT_SSID=$(nmcli -t -f ACTIVE,SSID dev wifi | grep '^yes' | cut -d: -f2 || true)
     printf '{"status":"success","state":"connected","interface":"%s","ssid":"%s"}\n' "$WIFI_IF" "$CURRENT_SSID" >&3
  else
     printf '{"status":"success","state":"disconnected","interface":"%s"}\n' "$WIFI_IF" >&3
  fi

elif [[ "$ACTION" == "list" ]]; then
  nmcli dev wifi rescan >/dev/null 2>&1 || true
  # Parse nmcli output into a JSON array
  NETWORKS=$(nmcli -t -f SSID,SIGNAL,SECURITY dev wifi list | awk -F: 'NF>=2 && $1!="" && $1!="--" {printf "{\"ssid\":\"%s\",\"signal\":\"%s\",\"security\":\"%s\"},", $1, $2, $3}' | sed 's/,$//' || true)
  printf '{"status":"success","networks":[%s]}\n' "$NETWORKS" >&3

elif [[ "$ACTION" == "connect" ]]; then
  if [[ -z "$SSID" ]]; then
    printf '{"status":"error","message":"SSID is required"}\n' >&3
    exit 0
  fi
  
  # Attempt connection silently
  if nmcli dev wifi connect "$SSID" password "$PASS" ifname "$WIFI_IF" >/dev/null 2>&1; then
    # Wait a moment and check if internet actually works
    if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
      printf '{"status":"success","message":"Connected to %s and internet is reachable"}\n' "$SSID" >&3
    else
      printf '{"status":"warning","message":"Connected to %s, but no internet access"}\n' "$SSID" >&3
    fi
  else
    printf '{"status":"error","message":"Failed to connect to %s. Check password."}\n' "$SSID" >&3
  fi
else
  printf '{"status":"error","message":"Invalid action"}\n' >&3
fi