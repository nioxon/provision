#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_ROOT/core/utils.sh"

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Error: MySQL/MariaDB setup must be run as root. Please use sudo.${NC}" >&2
   exit 1
fi

echo -e "${YELLOW}🗄️ Installing MariaDB (MySQL)...${NC}"

export DEBIAN_FRONTEND=noninteractive

run_with_spinner "Installing MariaDB packages" apt_install mariadb-server mariadb-client
run_with_spinner "Starting MariaDB service" bash -c "systemctl enable mariadb >/dev/null 2>&1 && systemctl restart mariadb"

echo -e "${GREEN}✅ MariaDB installed and running.${NC}"
