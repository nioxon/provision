#!/usr/bin/env bash
set -e
source /opt/nioxon/config/server.env

mkdir -p $SITE_ROOT
chown -R www-data:www-data /var/www

cat > /etc/nginx/sites-available/$SITE_DOMAIN <<EOF
server {
  listen 80;
  server_name $SITE_DOMAIN;
  root $SITE_ROOT;
  index index.php index.html;

  location / {
    try_files \$uri \$uri/ /index.php?\$query_string;
  }

  location ~ \.php\$ {
    include snippets/fastcgi-php.conf;
    fastcgi_pass unix:/run/php/php8.3-fpm.sock;
  }
}
EOF

ln -sf /etc/nginx/sites-available/$SITE_DOMAIN /etc/nginx/sites-enabled/
nginx -t && systemctl reload nginx
