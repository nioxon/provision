#!/usr/bin/env bash
set -e
source /opt/nioxon/config/server.env

curl -fsSL https://deb.nodesource.com/setup_$NODE_VERSION.x | bash -
apt install -y nodejs
npm install -g pm2
