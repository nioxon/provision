#!/bin/bash
set -euo pipefail

# Terminal Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Error: Nginx vhost setup must be run as root. Please use sudo.${NC}" >&2
   exit 1
fi

if [[ $# -lt 3 ]]; then
  echo -e "${RED}Error: Missing arguments. Usage: 02-nginx-vhost.sh <domain> <type> <bind_ip>${NC}" >&2
  exit 1
fi

DOMAIN="$1"
TYPE="$2"
BIND_IP="$3"

WEBROOT="/home/forge/$DOMAIN/public"

mkdir -p "/home/forge/$DOMAIN"

echo -e "${YELLOW}🌐 Creating Nginx site for ${BLUE}$DOMAIN${YELLOW} on ${BLUE}$BIND_IP${NC}..."

cat > "/etc/nginx/sites-available/$DOMAIN" <<EOF
server {
    listen $BIND_IP:80;
    server_name $DOMAIN;

    root $WEBROOT;
    index index.php index.html;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.3-fpm.sock;
    }

    access_log /var/log/nginx/$DOMAIN.access.log;
    error_log  /var/log/nginx/$DOMAIN.error.log;
}
EOF

ln -sf "/etc/nginx/sites-available/$DOMAIN" "/etc/nginx/sites-enabled/"

if ! nginx -t >/dev/null 2>&1; then
  echo -e "${RED}❌ Nginx configuration test failed for $DOMAIN.${NC}" >&2
  exit 1
fi
systemctl reload nginx

echo -e "${GREEN}✅ Site bound to ${BLUE}$BIND_IP:80${NC}"
