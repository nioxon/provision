#!/usr/bin/env bash
set -e

add-apt-repository -y ppa:ondrej/php || true
apt update -y

apt install -y \
  php8.3 \
  php8.3-fpm \
  php8.3-cli \
  php8.3-mysql \
  php8.3-curl \
  php8.3-zip \
  php8.3-mbstring \
  php8.3-xml \
  php8.3-gd

systemctl enable php8.3-fpm
systemctl restart php8.3-fpm
