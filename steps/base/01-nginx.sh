#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_ROOT/core/utils.sh"

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Error: Nginx setup must be run as root. Please use sudo.${NC}" >&2
   exit 1
fi

echo -e "${YELLOW}🌐 Installing and configuring Nginx...${NC}"

export DEBIAN_FRONTEND=noninteractive

run_with_spinner "Installing Nginx server" apt_install nginx
run_with_spinner "Starting Nginx service" bash -c "systemctl enable nginx >/dev/null 2>&1 && systemctl restart nginx"

echo -e "${GREEN}✅ Nginx installed and running.${NC}"
