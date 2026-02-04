#!/usr/bin/env bash
set -e

apt install -y certbot python3-certbot-nginx

grep '- domain:' /opt/nioxon/config/server.yaml | while read -r line; do
  DOMAIN=$(echo "$line" | awk '{print $3}')
  SSL=$(grep -A3 "$DOMAIN" /opt/nioxon/config/server.yaml | grep ssl | awk '{print $2}')

  if [ "$SSL" = "true" ]; then
    echo "🔐 Enabling SSL for $DOMAIN"
    certbot --nginx -d "$DOMAIN" -d "www.$DOMAIN" --non-interactive --agree-tos -m admin@$DOMAIN || true
  fi
done
