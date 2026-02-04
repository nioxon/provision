#!/usr/bin/env bash
set -e
apt install -y redis-server
systemctl enable redis-server
systemctl start redis-server
