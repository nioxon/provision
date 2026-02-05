#!/usr/bin/env bash
set -e

echo "🚀 Installing NIOXON CLI"

apt update -y
apt install -y git curl ca-certificates

# Always clone cleanly
if [ ! -d /opt/nioxon/.git ]; then
  rm -rf /opt/nioxon
  git clone https://github.com/nioxon/provision.git /opt/nioxon
else
  cd /opt/nioxon && git pull
fi

# Ensure CLI exists
if [ ! -f /opt/nioxon/bin/nioxon ]; then
  echo "❌ bin/nioxon missing in repo"
  exit 1
fi

chmod +x /opt/nioxon/bin/nioxon

# Global launcher (PATH-safe)
cat > /usr/bin/nioxon <<'EOF'
#!/usr/bin/env bash
exec /opt/nioxon/bin/nioxon "$@"
EOF
chmod +x /usr/bin/nioxon

echo "✔ NIOXON installed"
echo "👉 Run: nioxon setup"
