#!/usr/bin/env bash
set -e

PHP_VERSION=8.3

add-apt-repository ppa:ondrej/php -y
apt update -y

apt install -y \
  php$PHP_VERSION \
  php$PHP_VERSION-fpm \
  php$PHP_VERSION-cli \
  php$PHP_VERSION-mysql \
  php$PHP_VERSION-curl \
  php$PHP_VERSION-mbstring \
  php$PHP_VERSION-xml \
  php$PHP_VERSION-zip

systemctl enable php$PHP_VERSION-fpm
systemctl restart php$PHP_VERSION-fpm
