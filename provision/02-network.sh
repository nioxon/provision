#!/usr/bin/env bash
set -e

apt install -y network-manager

systemctl enable NetworkManager
systemctl restart NetworkManager
