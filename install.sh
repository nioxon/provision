#!/usr/bin/env bash
set -e

echo "🚀 Installing / Updating NIOXON Provisioning Engine"

# Must run as root
if [ "$EUID" -ne 0 ]; then
  echo "❌ Please run as root (use sudo)"
  exit 1
fi

NIOXON_DIR="/opt/nioxon"
REPO_URL="https://github.com/nioxon/provision.git"
BRANCH="main"

echo "📦 Installing base dependencies"
apt update -y
apt install -y git curl ca-certificates

# Ensure /opt exists
mkdir -p /opt

if [ -d "$NIOXON_DIR/.git" ]; then
  echo "🔄 Resetting existing NIOXON installation to GitHub state"
  cd "$NIOXON_DIR"

  # Hard reset to avoid merge conflicts (SERVER IS DISPOSABLE)
  git fetch origin
  git reset --hard "origin/$BRANCH"
else
  echo "📥 Cloning NIOXON repository"
  git clone -b "$BRANCH" "$REPO_URL" "$NIOXON_DIR"
fi

echo "🔧 Setting permissions"
chmod +x "$NIOXON_DIR/bin/nioxon"
chmod +x "$NIOXON_DIR/provision/"*.sh

echo "🔗 Installing global nioxon command"
ln -sf "$NIOXON_DIR/bin/nioxon" /usr/local/bin/nioxon

echo ""
echo "✅ NIOXON is installed and synced with GitHub"
echo "👉 Next step: run 'sudo nioxon install'"
