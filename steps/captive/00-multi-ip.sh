#!/bin/bash
set -euo pipefail

# Terminal Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Error: Multi-IP setup must be run as root. Please use sudo.${NC}" >&2
   exit 1
fi

echo -e "${YELLOW}🚍 Setting up Multi-IP LAN Aliases...${NC}"

# Safely extract interface and prevent pipefail crash
LAN_IF=$(ip link | grep -E "en|eth" | head -n 1 | awk -F: '{print $2}' | xargs || true)

if [[ -z "$LAN_IF" ]]; then
  echo -e "${RED}❌ No suitable LAN interface (en/eth) detected.${NC}" >&2
  exit 1
fi

echo -e "${GREEN}Detected LAN Interface: ${BLUE}$LAN_IF${NC}"

cat > /etc/netplan/99-nioxplay-lan.yaml <<EOF
network:
  version: 2
  renderer: networkd
  ethernets:
    $LAN_IF:
      dhcp4: no
      addresses:
        - 10.10.10.2/24   # Captive Gateway
        - 10.10.10.3/24   # NioxPlay Portal
        - 10.10.10.4/24   # Admin Panel
        - 10.10.10.5/24   # Bus Owner Panel
        - 10.10.10.6/24   # Advertise Portal
EOF

echo -e "Applying Netplan..."

if ! netplan apply; then
  echo -e "${RED}❌ Failed to apply Netplan configuration.${NC}" >&2
  exit 1
fi

echo -e "${GREEN}✅ Multi-IP aliases configured successfully!${NC}"
echo -e "Server now responds on:"
echo -e "  ${BLUE}10.10.10.2${NC} - Captive"
echo -e "  ${BLUE}10.10.10.3${NC} - Portal"
echo -e "  ${BLUE}10.10.10.4${NC} - Admin"
echo -e "  ${BLUE}10.10.10.5${NC} - Owner"
echo -e "  ${BLUE}10.10.10.6${NC} - Ads"
