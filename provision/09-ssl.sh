#!/usr/bin/env bash
set -e
source /opt/nioxon/config/server.env

SSL_DIR="/etc/nginx/ssl"
CERT="$SSL_DIR/$SITE_DOMAIN.crt"
KEY="$SSL_DIR/$SITE_DOMAIN.key"
CONF="/etc/nginx/sites-available/$SITE_DOMAIN"

echo "🔐 Setting up self-signed SSL for $SITE_DOMAIN"

mkdir -p "$SSL_DIR"

# Generate certificate only if not exists
if [ ! -f "$CERT" ] || [ ! -f "$KEY" ]; then
  echo "📜 Generating self-signed certificate"
  openssl req -x509 -nodes -days 365 \
    -newkey rsa:2048 \
    -keyout "$KEY" \
    -out "$CERT" \
    -subj "/C=IN/ST=State/L=City/O=NIOXON/OU=Dev/CN=$SITE_DOMAIN"
fi

# Update Nginx config (overwrite safely)
cat > "$CONF" <<EOF
server {
    listen 80;
    server_name $SITE_DOMAIN;
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl;
    server_name $SITE_DOMAIN;

    ssl_certificate $CERT;
    ssl_certificate_key $KEY;

    root $SITE_ROOT;
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

nginx -t
systemctl reload nginx

echo "✅ SSL enabled for $SITE_DOMAIN"
