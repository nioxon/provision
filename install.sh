#!/usr/bin/env bash
set -euo pipefail

echo "🚀 Installing NIOXON"

# OS guard
if [ "$(lsb_release -cs)" != "jammy" ]; then
  echo "❌ Ubuntu 22.04 LTS only"
  exit 1
fi

# Internet guard
curl -fsSL https://github.com >/dev/null || {
  echo "❌ Internet not available (HTTPS failed)"
  exit 1
}

apt update -y
apt install -y git curl ca-certificates jq

rm -rf /opt/nioxon
git clone --depth=1 https://github.com/nioxon/provision.git /opt/nioxon

chmod +x /opt/nioxon/bin/nioxon

cat > /usr/bin/nioxon <<'EOF'
#!/usr/bin/env bash
exec /opt/nioxon/bin/nioxon "$@"
EOF
chmod +x /usr/bin/nioxon

echo "✔ Installed"
echo "👉 Run: nioxon setup"
