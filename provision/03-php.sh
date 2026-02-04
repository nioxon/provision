#!/usr/bin/env bash
set -e
source "$(dirname "$0")/helpers.sh"

PHP_VERSION=$(grep 'version:' /opt/nioxon/config/server.yaml | awk '{print $2}' | tr -d '"')

echo "🐘 Installing PHP $PHP_VERSION"

if ! grep -q ondrej/php /etc/apt/sources.list.d/* 2>/dev/null; then
  add-apt-repository ppa:ondrej/php -y
  apt update
fi

PACKAGES=(
  php$PHP_VERSION
  php$PHP_VERSION-fpm
  php$PHP_VERSION-cli
  php$PHP_VERSION-mysql
  php$PHP_VERSION-curl
  php$PHP_VERSION-mbstring
  php$PHP_VERSION-xml
  php$PHP_VERSION-zip
  php$PHP_VERSION-bcmath
)

apt install -y "${PACKAGES[@]}"

update-alternatives --set php /usr/bin/php$PHP_VERSION
systemctl enable php$PHP_VERSION-fpm
systemctl restart php$PHP_VERSION-fpm
