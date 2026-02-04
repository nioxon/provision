#!/usr/bin/env bash
set -e

echo "🚀 Installing NIOXON Provisioning Engine"

# Must be root
if [ "$EUID" -ne 0 ]; then
  echo "❌ Please run as root (use sudo)"
  exit 1
fi

NIOXON_DIR="/opt/nioxon"
REPO_URL="https://github.com/nioxon/provision.git"

echo "📦 Installing base dependencies"
apt update
apt install -y git curl ca-certificates

# Clone or update repo
if [ -d "$NIOXON_DIR/.git" ]; then
  echo "🔄 Updating existing NIOXON installation"
  cd "$NIOXON_DIR"
  git pull
else
  echo "📥 Cloning NIOXON repo"
  git clone "$REPO_URL" "$NIOXON_DIR"
fi

# Permissions
chmod +x "$NIOXON_DIR/bin/nioxon"
chmod +x "$NIOXON_DIR/provision/"*.sh

# Install CLI globally
ln -sf "$NIOXON_DIR/bin/nioxon" /usr/local/bin/nioxon

echo ""
echo "✅ NIOXON installed successfully"
echo "👉 Next step: run 'nioxon install'"
