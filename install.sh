#!/usr/bin/env bash
set -euo pipefail

echo "🚀 Installing NIOXON CLI"

# --------------------------------------------------
# 1. HARD OS CHECK
# --------------------------------------------------
if [ "$(lsb_release -cs)" != "jammy" ]; then
  echo "❌ Unsupported OS"
  echo "NIOXON supports Ubuntu 22.04 LTS only"
  exit 1
fi

# --------------------------------------------------
# 2. INTERNET SANITY CHECK (HTTPS, NOT DNS)
# --------------------------------------------------
if ! curl -fsSL https://github.com >/dev/null 2>&1; then
  echo "❌ Internet not reachable (HTTPS failed)"
  echo "Make sure captive portal is NOT active"
  exit 1
fi

# --------------------------------------------------
# 3. BASE DEPENDENCIES
# --------------------------------------------------
export DEBIAN_FRONTEND=noninteractive
apt update -y
apt install -y git curl ca-certificates

# --------------------------------------------------
# 4. CLEAN CLONE (NO git pull EVER)
# --------------------------------------------------
rm -rf /opt/nioxon
git clone --depth=1 https://github.com/nioxon/provision.git /opt/nioxon

# --------------------------------------------------
# 5. VERIFY CLI EXISTS
# --------------------------------------------------
if [ ! -f /opt/nioxon/bin/nioxon ]; then
  echo "❌ bin/nioxon missing in repository"
  echo "Repo is invalid or incomplete"
  exit 1
fi

chmod +x /opt/nioxon/bin/nioxon

# --------------------------------------------------
# 6. GLOBAL LAUNCHER (PATH SAFE)
# --------------------------------------------------
cat > /usr/bin/nioxon <<'EOF'
#!/usr/bin/env bash
exec /opt/nioxon/bin/nioxon "$@"
EOF

chmod +x /usr/bin/nioxon

# --------------------------------------------------
# 7. FINAL VERIFICATION
# --------------------------------------------------
if ! command -v nioxon >/dev/null; then
  echo "❌ NIOXON command not found after install"
  exit 1
fi

echo ""
echo "✔ NIOXON CLI installed successfully"
echo "👉 Run: nioxon setup"
