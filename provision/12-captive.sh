#!/usr/bin/env bash
set -e
source /opt/nioxon/config/runtime.env

CAPTIVE_ROOT="/var/www/captive"
NGINX_AVAIL="/etc/nginx/sites-available"
NGINX_ENAB="/etc/nginx/sites-enabled"

mkdir -p "$CAPTIVE_ROOT"

cat > "$CAPTIVE_ROOT/index.html" <<EOF
<!DOCTYPE html>
<html>
<head>
  <title>NioxPlay</title>
  <meta name="viewport" content="width=device-width, initial-scale=1">
</head>
<body style="font-family:sans-serif;text-align:center">
  <h1>🎬 Welcome to NioxPlay</h1>
  <p>Local streaming available</p>
  <a href="http://$SITE_DOMAIN">Continue</a>
</body>
</html>
EOF

cat > "$NGINX_AVAIL/captive.conf" <<EOF
server {
  listen 80 default_server;
  server_name _;

  root /var/www/captive;
  index index.html;

  location / {
    try_files \$uri /index.html;
  }
}
EOF

rm -f "$NGINX_ENAB/default"
ln -sf "$NGINX_AVAIL/captive.conf" "$NGINX_ENAB/captive.conf"

nginx -t
systemctl reload nginx
