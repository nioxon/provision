#!/usr/bin/env bash
set -e

apt install -y ufw

ufw allow OpenSSH
ufw allow 80/tcp
ufw allow 443/tcp

ufw --force enable
