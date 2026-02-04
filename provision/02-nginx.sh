#!/usr/bin/env bash
set -e

apt install -y nginx
systemctl enable nginx
systemctl start nginx
