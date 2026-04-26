#!/bin/bash
set -euo pipefail

# Terminal Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Error: Self-update must be run as root. Please use sudo.${NC}" >&2
   exit 1
fi

echo -e "\n${BLUE}======================================================${NC}"
echo -e "${BOLD}🔄 NIOXPLAY CLI AUTO-UPDATER${NC}"
echo -e "${BLUE}======================================================${NC}\n"

echo -e "➤ Pulling latest version from GitHub..."
cd "$PROJECT_ROOT"

if git pull -q; then
  echo -e "➤ Refreshing executable permissions..."
  chmod +x "$PROJECT_ROOT/bin/nioxplay.sh"
  echo -e "\n${GREEN}${BOLD}✅ NioxPlay CLI updated successfully!${NC}\n"
else
  echo -e "\n${RED}❌ Failed to update NioxPlay CLI. Please check your network or git status.${NC}\n" >&2
  exit 1
fi