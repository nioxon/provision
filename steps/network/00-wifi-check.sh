#!/bin/bash
set -euo pipefail

# Terminal Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Error: WiFi check must be run as root. Please use sudo.${NC}" >&2
   exit 1
fi

echo -e "${YELLOW}📡 Checking USB WiFi (WAN Internet)...${NC}"

# Auto-detect WiFi interface
WIFI_IF=$(iw dev 2>/dev/null | awk '$1=="Interface"{print $2}' | head -n1 || true)

if [[ -z "$WIFI_IF" ]]; then
  echo -e "${RED}❌ No WiFi adapter detected.${NC}"
  echo -e "${YELLOW}➡ Please plug USB WiFi dongle and retry.${NC}"
  exit 1
fi

echo -e "${GREEN}✅ WiFi Interface Detected: ${BLUE}$WIFI_IF${NC}"

# Check connection status
STATUS=$(nmcli -t -f DEVICE,STATE dev | grep "^$WIFI_IF" | cut -d: -f2 || true)

if [[ "$STATUS" != "connected" ]]; then
  echo -e "${YELLOW}⚠ WiFi is not connected to any network.${NC}"

  echo ""
  echo -e "Available Networks:"
  nmcli dev wifi list | head -n 10

  echo ""
  read -r -p "Enter WiFi SSID to connect: " SSID
  read -r -s -p "Enter WiFi Password: " PASS
  echo ""

  nmcli dev wifi connect "$SSID" password "$PASS" ifname "$WIFI_IF"
fi

echo ""
echo -e "${YELLOW}🌍 Testing Internet Connectivity...${NC}"

# Loop until internet works
while true; do
  if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Internet Connected Successfully!${NC}"
    break
  else
    echo -e "${RED}⚠ Internet not reachable. Retrying in 3 seconds...${NC}"
    sleep 3
  fi
done

echo -e "${GREEN}🚀 WAN Ready on ${BLUE}$WIFI_IF${NC}"
