#!/bin/bash
set -euo pipefail

# Terminal Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Error: DNS setup must be run as root. Please use sudo.${NC}" >&2
   exit 1
fi

echo -e "${YELLOW}📡 Configuring DNS & DHCP (dnsmasq)...${NC}"

if [[ ! -f /tmp/nioxplay-lan-interface ]]; then
  echo -e "${RED}Error: LAN interface config not found (/tmp/nioxplay-lan-interface). Run 01-lan.sh first.${NC}" >&2
  exit 1
fi

LAN_IF=$(cat /tmp/nioxplay-lan-interface)
echo -e "Using interface: ${BLUE}$LAN_IF${NC}"

export DEBIAN_FRONTEND=noninteractive
apt-get install -qq -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" dnsmasq

cat > /etc/dnsmasq.conf <<EOF
interface=$LAN_IF

dhcp-range=10.10.10.100,10.10.10.150,12h

dhcp-option=3,10.10.10.2
dhcp-option=6,10.10.10.2

address=/#/10.10.10.2
EOF

systemctl restart dnsmasq
systemctl enable dnsmasq >/dev/null 2>&1 || true

echo -e "${GREEN}✅ DHCP Pool Active: ${BLUE}10.10.10.100–150${NC}"
