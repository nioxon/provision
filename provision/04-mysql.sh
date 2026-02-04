#!/usr/bin/env bash
set -e
source /opt/nioxon/config/server.env

apt install -y mysql-server

mysql <<EOF
ALTER USER 'root'@'localhost'
IDENTIFIED WITH mysql_native_password BY '$MYSQL_ROOT_PASSWORD';
DELETE FROM mysql.user WHERE User='';
DROP DATABASE IF EXISTS test;
FLUSH PRIVILEGES;
EOF
