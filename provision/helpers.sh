#!/usr/bin/env bash
set -e

PHP_VERSION=$(grep 'version:' /opt/nioxon/config/server.yaml | awk '{print $2}' | tr -d '"')

grep '- domain:' /opt/nioxon/config/server.yaml | while read -r line; do
  DOMAIN=$(echo "$line" | awk '{print $3}')
  ROOT=$(grep -A3 "$DOMAIN" /opt/nioxon/config/server.yaml | grep root | awk '{print $2}')

  SITE_CONF="/etc/nginx/sites-available/$DOMAIN"

  if [ ! -f "$SITE_CONF" ]; then
    echo "🌐 Creating site $DOMAIN"

    mkdir -p "$(dirname "$ROOT")"

    cat > "$SITE_CONF" <<EOF
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;
    root $ROOT;

    index index.php index.html;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php$PHP_VERSION-fpm.sock;
    }
}
EOF

    ln -sf "$SITE_CONF" /etc/nginx/sites-enabled/
  fi
done

nginx -t && systemctl reload nginx
