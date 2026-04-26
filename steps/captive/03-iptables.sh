#!/bin/bash
set -euo pipefail

# Terminal Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Error: iptables setup must be run as root. Please use sudo.${NC}" >&2
   exit 1
fi

echo -e "${YELLOW}🔐 Configuring Captive Portal Redirects (iptables)...${NC}"

if [[ ! -f /tmp/nioxplay-lan-interface ]]; then
  echo -e "${RED}Error: LAN interface config not found (/tmp/nioxplay-lan-interface). Run 01-lan.sh first.${NC}" >&2
  exit 1
fi

LAN_IF=$(cat /tmp/nioxplay-lan-interface)

export DEBIAN_FRONTEND=noninteractive

echo iptables-persistent iptables-persistent/autosave_v4 boolean true | debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean true | debconf-set-selections
apt-get install -qq -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" iptables-persistent

iptables -t nat -F

iptables -t nat -A PREROUTING -i "$LAN_IF" -p tcp --dport 80 \
-j DNAT --to-destination 10.10.10.2:80

iptables-save > /etc/iptables/rules.v4

echo -e "${GREEN}✅ Captive Redirect Enabled on ${BLUE}$LAN_IF${NC}"
