#!/bin/bash
set -euo pipefail

# Terminal Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

REPO_URL="https://github.com/nioxon/provision.git"
INSTALL_DIR="/opt/nioxplay-provision"
BIN_TARGET="/usr/local/bin/nioxplay"

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Error: This script must be run as root. Please use sudo.${NC}" >&2
   exit 1
fi

echo -e "${CYAN}${BOLD}"
echo '    _   ___           ____  __           '
echo '   / | / (_)___  _  _/ __ \/ /___ ___  __'
echo '  /  |/ / / __ \| |/_/ /_/ / / __ `/ / / /'
echo ' / /|  / / /_/ />  </ ____/ / /_/ / /_/ / '
echo '/_/ |_/_/\____/_/|_/_/   /_/\__,_/\__, /  '
echo '                                 /____/   '
echo -e "${NC}\n"

echo -e "${BOLD}🚍 Bootstrapping NioxPlay Provision CLI...${NC}\n"
echo -e "➤ Installing system dependencies..."

export DEBIAN_FRONTEND=noninteractive
apt-get update -qq -y
apt-get install -qq -y git curl

if [[ ! -d "$INSTALL_DIR" ]]; then
  echo -e "➤ Cloning GitHub repository..."
  git clone -q "$REPO_URL" "$INSTALL_DIR"
else
  echo -e "➤ Updating existing repository..."
  git -C "$INSTALL_DIR" pull -q
fi

echo -e "➤ Setting up executable permissions..."
chmod +x "$INSTALL_DIR/bin/nioxplay.sh"
ln -sf "$INSTALL_DIR/bin/nioxplay.sh" "$BIN_TARGET"

echo -e "\n${GREEN}${BOLD}✅ CLI Installed Successfully!${NC}"
echo -e "Run:"
echo -e "   ${BLUE}nioxplay provision${NC}"
