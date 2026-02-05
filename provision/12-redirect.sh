#!/usr/bin/env bash
set -e
source /opt/nioxon/config/runtime.env

mkdir -p /var/www/captive
cat > /var/www/captive/index.html <<EOF
<!DOCTYPE html>
<html>
<head>
  <title>Welcome to NioxPlay</title>
  <meta name="viewport" content="width=device-width, initial-scale=1">
</head>
<body style="font-family:sans-serif;text-align:center">
  <h1>🎬 Welcome to NioxPlay</h1>
  <p>Enjoy local streaming without internet</p>
  <a href="http://${SITE_DOMAIN}">Continue</a>
</body>
</html>
EOF

cat > /etc/nginx/sites-available/captive <<EOF
server {
  listen 80 default_server;
  server_name _;
  root /var/www/captive;
  index index.html;
}
EOF

ln -sf /etc/nginx/sites-available/captive /etc/nginx/sites-enabled/captive
rm -f /etc/nginx/sites-enabled/default
nginx -t
systemctl reload nginx
