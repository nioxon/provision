#!/usr/bin/env bash
set -e

dpkg -s mysql-server >/dev/null 2>&1 || apt install -y mysql-server

systemctl enable mysql
systemctl restart mysql
