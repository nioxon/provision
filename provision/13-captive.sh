#!/usr/bin/env bash
set -e
source /opt/nioxon/config/server.env

cat > /etc/nginx/sites-available/captive <<EOF
server {
  listen 80 default_server;
  server_name _;
  return 302 http://$SITE_DOMAIN;
}
EOF

ln -sf /etc/nginx/sites-available/captive /etc/nginx/sites-enabled/captive
nginx -t && systemctl reload nginx
