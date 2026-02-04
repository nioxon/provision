#!/usr/bin/env bash
set -e
apt install -y ufw openssh-server
ufw allow ssh
ufw allow 80
ufw allow 443
ufw --force enable
