#!/usr/bin/env bash
set -e
source /opt/nioxon/config/server.env

mkdir -p "$SITE_ROOT"
chown -R www-data:www-data /var/www/$SITE_DOMAIN

CONF="/etc/nginx/sites-available/$SITE_DOMAIN"

if [ ! -f "$CONF" ]; then
cat > "$CONF" <<EOF
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
        fastcgi_pass unix:/run/php/php$PHP_VERSION-fpm.sock;
    }
}
EOF

ln -sf "$CONF" /etc/nginx/sites-enabled/
nginx -t && systemctl reload nginx
fi
