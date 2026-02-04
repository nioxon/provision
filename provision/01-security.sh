#!/usr/bin/env bash
set -e

apt install -y ufw
ufw allow OpenSSH
ufw allow 80
ufw allow 443
ufw --force enable
