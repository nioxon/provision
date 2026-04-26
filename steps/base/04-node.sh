#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_ROOT/core/utils.sh"

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Error: Node.js setup must be run as root. Please use sudo.${NC}" >&2
   exit 1
fi

echo -e "${YELLOW}🟩 Installing Node.js (v22.x) and PM2...${NC}"

export DEBIAN_FRONTEND=noninteractive

run_with_spinner "Fetching NodeSource repository" bash -c "curl -fsSL https://deb.nodesource.com/setup_22.x | bash - >/dev/null 2>&1"
run_with_spinner "Installing Node.js runtime" apt_install nodejs
run_with_spinner "Installing PM2 globally" npm install -g pm2 --quiet

echo -e "${GREEN}✅ Node.js and PM2 installed successfully.${NC}"
