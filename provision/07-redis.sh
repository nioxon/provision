#!/usr/bin/env bash
set -e

dpkg -s redis-server >/dev/null 2>&1 || apt install -y redis-server

systemctl enable redis-server
systemctl restart redis-server
