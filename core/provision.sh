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
   echo -e "${RED}Error: Provisioning must be run as root. Please use sudo.${NC}" >&2
   exit 1
fi

TOTAL_STEPS=9
CURRENT_STEP=0

function run_step() {
  local step_name="$1"
  local step_file="$2"
  local step_path="$PROJECT_ROOT/$step_file"

  if [[ ! -f "$step_path" ]]; then
    echo -e "${RED}Error: Step script not found at ${step_path}${NC}" >&2
    exit 1
  fi

  CURRENT_STEP=$((CURRENT_STEP + 1))
  local percentage=$((CURRENT_STEP * 100 / TOTAL_STEPS))
  local width=40
  local completed=$((width * CURRENT_STEP / TOTAL_STEPS))
  local remaining=$((width - completed))

  echo -e "${DIM}------------------------------------------------------${NC}"
  printf "${BOLD}${CYAN}⌛ PROGRESS: [${GREEN}%s${NC}${DIM}%s${NC}${BOLD}${CYAN}] %3d%%${NC}\n" \
    "$(printf "%${completed}s" | tr ' ' '█')" \
    "$(printf "%${remaining}s" | tr ' ' '░')" \
    "$percentage"
  echo -e "${BOLD}${BLUE}▶ RUNNING:${NC} ${step_name}"
  echo -e "${DIM}------------------------------------------------------${NC}\n"

  bash "$step_path"
  echo ""
}

echo -e "\n${BLUE}======================================================${NC}"
echo -e "${BOLD}🚀 NIOXPLAY SERVER PROVISIONING${NC}"
echo -e "${BLUE}======================================================${NC}\n"

run_step "System Packages & Firewall" "steps/base/00-system.sh"
run_step "Security & User Setup" "steps/base/01-security.sh"
run_step "Nginx Web Server" "steps/base/02-nginx.sh"
run_step "PHP 8.3 & Composer" "steps/base/03-php.sh"
run_step "MariaDB (MySQL)" "steps/base/04-mysql.sh"
run_step "Node.js & PM2" "steps/base/05-node.sh"
run_step "Redis Server" "steps/base/06-redis.sh"
run_step "Process Supervisor" "steps/base/07-supervisor.sh"
run_step "Static LAN Network" "steps/network/01-lan-static.sh"

echo -e "\n${GREEN}${BOLD}✅ Base Provisioning Completed Successfully!${NC}\n"