#!/usr/bin/env bash
set -e
source "$(dirname "$0")/helpers.sh"

MYSQL_ROOT_PASSWORD=$(grep 'root_password:' /opt/nioxon/config/server.yaml | awk '{print $2}' | tr -d '"')

echo "🗄️ MySQL provisioning"

if ! is_installed mysql-server; then
  apt install -y mysql-server
fi

mysql -u root <<EOF
ALTER USER 'root'@'localhost'
IDENTIFIED WITH mysql_native_password
BY '$MYSQL_ROOT_PASSWORD';
DELETE FROM mysql.user WHERE User='';
DROP DATABASE IF EXISTS test;
FLUSH PRIVILEGES;
EOF
