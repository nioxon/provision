#!/bin/bash
set -euo pipefail

# Terminal Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Error: SSL renewal must be run as root. Please use sudo.${NC}" >&2
   exit 1
fi

echo -e "${YELLOW}🔄 Checking Let's Encrypt Certificate Renewals...${NC}"

# Check for internet connection first
if ! ping -c 1 8.8.8.8 >/dev/null 2>&1; then
  echo -e "${RED}❌ No internet connection detected.${NC}" >&2
  echo -e "${YELLOW}Certbot requires internet to communicate with the Cloudflare API.${NC}" >&2
  echo -e "Please run ${BLUE}sudo bash steps/network/00-wifi-check.sh${NC} to connect to WiFi first." >&2
  exit 1
fi

echo -e "${GREEN}✅ Internet connection verified.${NC}"
echo -e "Running Certbot renewal process..."

# Run renewal and automatically reload nginx if a cert was updated
export DEBIAN_FRONTEND=noninteractive
certbot renew --quiet --deploy-hook "systemctl reload nginx"

echo -e "${GREEN}✅ SSL Renewal process completed!${NC}"
echo -e "${BLUE}(Note: Certificates are only updated if they are within 30 days of expiration)${NC}"