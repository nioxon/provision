#!/bin/bash
set -euo pipefail

# Terminal Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Error: LAN verification must be run as root. Please use sudo.${NC}" >&2
   exit 1
fi

echo -e "${YELLOW}🚍 Verifying LAN Gateway...${NC}"

# Safely extract interface and prevent pipefail crash
LAN_IF=$(ip link | grep -E "en|eth" | head -n 1 | awk -F: '{print $2}' | xargs || true)

if [[ -z "$LAN_IF" ]]; then
  echo -e "${RED}❌ No suitable LAN interface (en/eth) detected.${NC}" >&2
  exit 1
fi

if ip a show "$LAN_IF" | grep -q "10.10.10.2"; then
  echo -e "${GREEN}✅ Captive Gateway IP exists on ${BLUE}$LAN_IF${NC}"
else
  echo -e "${RED}⚠ Captive IP missing (netplan not applied)${NC}"
fi

echo "$LAN_IF" > /tmp/nioxplay-lan-interface
echo "10.10.10" > /tmp/nioxplay-subnet
