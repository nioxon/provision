#!/usr/bin/env bash
set -e

echo "🚀 Installing NIOXON"

if [ "$EUID" -ne 0 ]; then
  echo "❌ Run as root (sudo)"
  exit 1
fi

apt update
apt install -y git curl ca-certificates

if [ ! -d /opt/nioxon ]; then
  git clone https://github.com/nioxon/provision.git /opt/nioxon
else
  cd /opt/nioxon && git pull
fi

chmod +x /opt/nioxon/bin/nioxon
chmod +x /opt/nioxon/provision/*.sh

ln -sf /opt/nioxon/bin/nioxon /usr/local/bin/nioxon

echo "✅ NIOXON installed"
echo "👉 Run: nioxon install"
