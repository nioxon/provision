#!/usr/bin/env bash
set -e

apt install -y supervisor
systemctl enable supervisor
systemctl start supervisor
