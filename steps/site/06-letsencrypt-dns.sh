#!/bin/bash
set -euo pipefail

# Terminal Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Error: Let's Encrypt setup must be run as root. Please use sudo.${NC}" >&2
   exit 1
fi

if [[ $# -lt 2 ]]; then
  echo -e "${RED}Error: Missing arguments. Usage: 06-letsencrypt-dns.sh <domain> <email>${NC}" >&2
  exit 1
fi

DOMAIN="$1"
EMAIL="$2"
VHOST="/etc/nginx/sites-available/$DOMAIN"
CF_CRED_FILE="/root/.secrets/cloudflare.ini"

echo -e "${YELLOW}🔐 Setting up Let's Encrypt (DNS-01 Challenge) for ${BLUE}$DOMAIN${NC}..."

if [[ ! -f "$CF_CRED_FILE" ]]; then
  echo -e "${RED}Error: Cloudflare credentials not found at $CF_CRED_FILE.${NC}" >&2
  echo -e "Create the file with: dns_cloudflare_api_token = YOUR_TOKEN_HERE" >&2
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive
echo -e "Installing Certbot and Cloudflare DNS plugin..."
apt-get install -qq -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" certbot python3-certbot-dns-cloudflare

# Secure the credentials file (Certbot requires this)
chmod 600 "$CF_CRED_FILE"

echo -e "Requesting certificate via DNS challenge (this takes about 20-30 seconds)..."
certbot certonly \
  --dns-cloudflare \
  --dns-cloudflare-credentials "$CF_CRED_FILE" \
  --dns-cloudflare-propagation-seconds 20 \
  --email "$EMAIL" \
  --agree-tos \
  --non-interactive \
  -d "$DOMAIN" \
  -d "*.$DOMAIN" >/dev/null

CERT_CRT="/etc/letsencrypt/live/$DOMAIN/fullchain.pem"
CERT_KEY="/etc/letsencrypt/live/$DOMAIN/privkey.pem"

if [[ -f "$VHOST" && -f "$CERT_CRT" ]]; then
  echo -e "Updating Nginx configuration for valid SSL..."
  
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
  echo -e "${GREEN}✅ Valid Let's Encrypt SSL installed successfully! Users will see no warnings.${NC}"
else
  echo -e "${RED}❌ Certificate generation failed or VHOST not found.${NC}" >&2
  exit 1
fi