#!/usr/bin/env bash
set -e
source /opt/nioxon/config/server.env

SSL_DIR=/etc/nginx/ssl
mkdir -p $SSL_DIR

openssl req -x509 -nodes -days 365 \
  -newkey rsa:2048 \
  -keyout $SSL_DIR/$SITE_DOMAIN.key \
  -out $SSL_DIR/$SITE_DOMAIN.crt \
  -subj "/CN=$SITE_DOMAIN"
