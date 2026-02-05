#!/usr/bin/env bash
set -e

echo "🚀 Installing NIOXON CLI"
echo "----------------------------------"

# -------------------------
# Requirements
# -------------------------
apt update -y
apt install -y git curl ca-certificates

# -------------------------
# Clone or update repo (CORRECT LOGIC)
# -------------------------
if [ ! -d /opt/nioxon/.git ]; then
  echo "📥 Cloning NIOXON repository"
  rm -rf /opt/nioxon
  git clone https://github.com/nioxon/provision.git /opt/nioxon
else
  echo "🔄 Updating NIOXON repository"
  cd /opt/nioxon
  git pull
fi

# -------------------------
# Ensure CLI exists
# -------------------------
if [ ! -f /opt/nioxon/bin/nioxon ]; then
  echo "❌ ERROR: bin/nioxon not found in repository"
  echo "Expected: /opt/nioxon/bin/nioxon"
  exit 1
fi

chmod +x /opt/nioxon/bin/nioxon

# -------------------------
# Install global launcher (PATH-SAFE)
# -------------------------
cat > /usr/bin/nioxon <<'EOF'
#!/usr/bin/env bash
exec /opt/nioxon/bin/nioxon "$@"
EOF

chmod +x /usr/bin/nioxon

# -------------------------
# Verify installation
# -------------------------
if ! /usr/bin/nioxon --help >/dev/null 2>&1; then
  echo "❌ NIOXON CLI verification failed"
  exit 1
fi

echo ""
echo "✔ NIOXON CLI installed successfully"
echo "👉 Next step: nioxon setup"
