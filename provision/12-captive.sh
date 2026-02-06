#!/usr/bin/env bash
set -e
source /opt/nioxon/config/runtime.env

mkdir -p /var/www/captive

cat > /var/www/captive/index.html <<EOF
<h1>Welcome to NioxPlay</h1>
<a href="http://$SITE_DOMAIN">Continue</a>
EOF

rm -f /etc/nginx/sites-enabled/default

cat > /etc/nginx/sites-available/captive.conf <<EOF
server {
  listen 80 default_server;
  server_name _;
  root /var/www/captive;
  index index.html;
}
EOF

ln -sf /etc/nginx/sites-available/captive.conf /etc/nginx/sites-enabled/
nginx -t
systemctl reload nginx
