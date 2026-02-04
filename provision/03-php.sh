#!/usr/bin/env bash
set -e
source /opt/nioxon/config/server.env

add-apt-repository ppa:ondrej/php -y
apt update

apt install -y \
 php$PHP_VERSION php$PHP_VERSION-fpm php$PHP_VERSION-cli \
 php$PHP_VERSION-mysql php$PHP_VERSION-curl \
 php$PHP_VERSION-mbstring php$PHP_VERSION-xml \
 php$PHP_VERSION-zip php$PHP_VERSION-bcmath

update-alternatives --set php /usr/bin/php$PHP_VERSION
systemctl enable php$PHP_VERSION-fpm
systemctl restart php$PHP_VERSION-fpm
