#!/usr/bin/env bash
set -e
source "$(dirname "$0")/helpers.sh"

echo "🌐 Nginx provisioning"

if ! is_installed nginx; then
  apt install -y nginx
fi

systemctl enable nginx

if ! service_running nginx; then
  systemctl start nginx
fi
