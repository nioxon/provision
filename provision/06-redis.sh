#!/usr/bin/env bash
set -e

if ! command -v redis-server &>/dev/null; then
  apt install -y redis-server
fi

systemctl enable redis-server
systemctl restart redis-server
