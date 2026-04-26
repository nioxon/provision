#!/bin/bash
set -euo pipefail

# Terminal Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Error: SSL setup must be run as root. Please use sudo.${NC}" >&2
   exit 1
fi

if [[ -z "${1:-}" ]]; then
  echo -e "${RED}Error: Domain name is required.${NC}" >&2
  exit 1
fi

DOMAIN="$1"
CERT_DIR="/etc/nginx/ssl"
CERT_KEY="$CERT_DIR/$DOMAIN.key"
CERT_CRT="$CERT_DIR/$DOMAIN.crt"
VHOST="/etc/nginx/sites-available/$DOMAIN"

echo -e "${YELLOW}🔐 Generating Self-Signed SSL for ${BLUE}$DOMAIN${NC}..."

mkdir -p "$CERT_DIR"

openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
  -keyout "$CERT_KEY" \
  -out "$CERT_CRT" \
  -subj "/C=US/ST=Local/L=Local/O=NioxPlay/CN=$DOMAIN" >/dev/null 2>&1

if [[ -f "$VHOST" ]]; then
  echo -e "Updating Nginx configuration for SSL..."
  
  # Safely inject SSL configuration directly under the listen :80 directive
  awk -v crt="$CERT_CRT" -v key="$CERT_KEY" '{
    print $0
    if ($0 ~ /listen.*:80;/) {
      sub(/:80;/, ":443 ssl;")
      print $0
      print "    ssl_certificate " crt ";"
      print "    ssl_certificate_key " key ";"
    }
  }' "$VHOST" > "${VHOST}.tmp" && mv "${VHOST}.tmp" "$VHOST"
  
  systemctl reload nginx
fi

echo -e "${GREEN}✅ SSL Setup complete! (Note: Browser warnings are normal for self-signed certs)${NC}"