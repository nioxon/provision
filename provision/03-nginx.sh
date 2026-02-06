#!/usr/bin/env bash
set -e

dpkg -s nginx >/dev/null 2>&1 || apt install -y nginx

# Remove Ubuntu default site (prevents duplicate default_server)
rm -f /etc/nginx/sites-enabled/default

nginx -t
systemctl enable nginx
systemctl restart nginx
