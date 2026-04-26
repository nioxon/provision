#!/bin/bash
set -euo pipefail

# Terminal Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Error: Network setup must be run as root. Please use sudo.${NC}" >&2
   exit 1
fi

echo -e "${YELLOW}🌐 Configuring Static LAN Interface...${NC}"

# Safely extract LAN interface and prevent pipefail crash
LAN_IF=$(ip link | grep -E "en|eth" | head -n 1 | awk -F: '{print $2}' | xargs || true)

if [[ -z "$LAN_IF" ]]; then
  echo -e "${RED}❌ No suitable LAN interface (en/eth) detected.${NC}" >&2
  exit 1
fi

echo -e "${GREEN}Detected LAN Interface: ${BLUE}$LAN_IF${NC}"

cat > /etc/netplan/01-nioxplay-base.yaml <<EOF
network:
  version: 2
  renderer: networkd
  ethernets:
    $LAN_IF:
      dhcp4: no
      addresses:
        - 10.10.10.1/24
EOF

echo -e "Applying Netplan configuration..."

if ! netplan apply; then
  echo -e "${RED}❌ Failed to apply Netplan configuration.${NC}" >&2
  exit 1
fi

echo -e "${GREEN}✅ Static LAN configured successfully on ${BLUE}10.10.10.1${NC} (${LAN_IF}).${NC}"