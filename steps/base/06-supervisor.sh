#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_ROOT/core/utils.sh"

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Error: Supervisor setup must be run as root. Please use sudo.${NC}" >&2
   exit 1
fi

echo -e "${YELLOW}🛠️ Installing Supervisor...${NC}"

export DEBIAN_FRONTEND=noninteractive

run_with_spinner "Installing Supervisor process manager" apt_install supervisor
run_with_spinner "Starting Supervisor service" bash -c "systemctl enable supervisor >/dev/null 2>&1 && systemctl restart supervisor"

echo -e "${GREEN}✅ Supervisor installed and running.${NC}"
