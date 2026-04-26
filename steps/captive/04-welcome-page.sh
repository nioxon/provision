#!/bin/bash
set -euo pipefail

# Terminal Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

if [[ -f "$PROJECT_ROOT/config.env" ]]; then
  source "$PROJECT_ROOT/config.env"
fi

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Error: Welcome page setup must be run as root. Please use sudo.${NC}" >&2
   exit 1
fi

CAPTIVE_IP="10.10.10.2"

echo -e "${YELLOW}🚍 Installing Captive Welcome Page...${NC}"

mkdir -p /var/www/captive

if [[ -n "${CAPTIVE_REPO_URL:-}" ]]; then
  echo -e "➤ Cloning Custom Captive Screen from GitHub..."
  export GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=no"
  git config --global --add safe.directory /var/www/captive
  
  if [[ -d "/var/www/captive/.git" ]]; then
    git -C /var/www/captive stash -q || true
    git -C /var/www/captive pull -q
  else
    rm -rf /var/www/captive/*
    git clone -q "$CAPTIVE_REPO_URL" /var/www/captive
  fi
else
  echo -e "➤ Generating default offline HTML page..."
cat > /var/www/captive/index.html <<EOF
<!DOCTYPE html>
<html>
<head>
  <title>NioxPlay WiFi</title>
  <meta name="viewport" content="width=device-width, initial-scale=1">
</head>
<body style="text-align:center;font-family:sans-serif;padding-top:60px;">

<h2>🚍 Welcome to NioxPlay WiFi</h2>
<p>Tap below to open entertainment portal.</p>

<a href="http://10.10.10.3"
style="padding:15px 25px;background:black;color:white;
border-radius:10px;text-decoration:none;font-size:18px;">
▶ Open NioxPlay Portal
</a>

</body>
</html>
EOF
fi

echo -e "Configuring Nginx captive site..."

cat > /etc/nginx/sites-available/captive <<EOF
server {
    listen $CAPTIVE_IP:80 default_server;
    server_name _;

    root /var/www/captive;
    index index.html;

    location / {
        try_files \$uri \$uri/ =404;
    }

    location /generate_204 {
        return 302 http://$CAPTIVE_IP/;
    }

    location /hotspot-detect.html {
        return 302 http://$CAPTIVE_IP/;
    }
}
EOF

rm -f /etc/nginx/sites-enabled/default
ln -sf /etc/nginx/sites-available/captive /etc/nginx/sites-enabled/captive

if ! nginx -t >/dev/null 2>&1; then
  echo -e "${RED}❌ Nginx configuration test failed.${NC}" >&2
  exit 1
fi
systemctl reload nginx

echo -e "${GREEN}✅ Captive Portal Active ONLY on ${BLUE}http://$CAPTIVE_IP${NC}"
