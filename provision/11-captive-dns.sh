#!/usr/bin/env bash
set -e
source /opt/nioxon/config/server.env

echo "🌍 Configuring Nginx captive redirect"

CONF="/etc/nginx/sites-available/captive"

cat > "$CONF" <<EOF
server {
    listen 80 default_server;
    server_name _;
    return 302 http://$SITE_DOMAIN;
}
EOF

ln -sf "$CONF" /etc/nginx/sites-enabled/captive

nginx -t
systemctl reload nginx

echo "✅ Nginx captive redirect enabled"
