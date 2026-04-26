#!/bin/bash
set -euo pipefail

# Terminal Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Error: Captive portal installation must be run as root. Please use sudo.${NC}" >&2
   exit 1
fi

if [[ -f "$PROJECT_ROOT/config.env" ]]; then
  source "$PROJECT_ROOT/config.env"
else
  echo -e "${RED}Error: config.env not found in ${PROJECT_ROOT}${NC}" >&2
  exit 1
fi

function run_step() {
  local step_file="$1"
  local step_path="$PROJECT_ROOT/$step_file"

  if [[ ! -f "$step_path" ]]; then
    echo -e "${RED}Error: Step script not found at ${step_path}${NC}" >&2
    exit 1
  fi

  bash "$step_path"
}

echo -e "\n${YELLOW}📡 Step 3: Installing Captive Portal Services${NC}"
echo -e "${YELLOW}--------------------------------------------${NC}"

run_step "steps/captive/00-multi-ip.sh"
run_step "steps/captive/01-lan.sh"
run_step "steps/captive/02-dns.sh"
run_step "steps/captive/03-iptables.sh"
run_step "steps/captive/04-welcome-page.sh"

echo -e "\n${GREEN}✅ Captive Portal Enabled!${NC}"
echo -e "Users will see captive page when connecting WiFi."
