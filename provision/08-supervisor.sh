#!/usr/bin/env bash
set -e

dpkg -s supervisor >/dev/null 2>&1 || apt install -y supervisor

systemctl enable supervisor
systemctl restart supervisor
