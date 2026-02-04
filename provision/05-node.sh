#!/usr/bin/env bash
set -e
source "$(dirname "$0")/helpers.sh"

NODE_VERSION=$(grep 'version:' /opt/nioxon/config/server.yaml | awk '{print $2}' | tr -d '"')

echo "🟢 Installing Node.js $NODE_VERSION"

if ! command -v node &>/dev/null; then
  curl -fsSL https://deb.nodesource.com/setup_$NODE_VERSION.x | bash -
  apt install -y nodejs
fi

if ! command -v pm2 &>/dev/null; then
  npm install -g pm2
fi
