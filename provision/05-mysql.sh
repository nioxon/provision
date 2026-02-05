#!/usr/bin/env bash
set -e
apt install -y mysql-server
systemctl enable mysql
systemctl start mysql
