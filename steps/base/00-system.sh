#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_ROOT/core/utils.sh"

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Error: System setup must be run as root. Please use sudo.${NC}" >&2
   exit 1
fi

echo -e "${YELLOW}🚀 Performing initial system setup...${NC}"

export DEBIAN_FRONTEND=noninteractive

run_with_spinner "Updating package lists" apt_update
run_with_spinner "Upgrading system packages" apt_upgrade
run_with_spinner "Installing base dependencies" apt_install curl git unzip zip net-tools software-properties-common pv
run_with_spinner "Installing firewall & Fail2Ban" apt_install ufw fail2ban
run_with_spinner "Configuring UFW rules" bash -c "ufw allow OpenSSH >/dev/null && ufw allow 80/tcp >/dev/null && ufw allow 443/tcp >/dev/null && yes | ufw enable >/dev/null 2>&1"
run_with_spinner "Starting Fail2Ban service" bash -c "systemctl enable fail2ban >/dev/null 2>&1 && systemctl restart fail2ban"

echo -e "${GREEN}✅ Base system and firewall configured.${NC}"