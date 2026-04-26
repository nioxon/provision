#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_ROOT/core/utils.sh"

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Error: Redis setup must be run as root. Please use sudo.${NC}" >&2
   exit 1
fi

echo -e "${YELLOW}🔴 Installing Redis Server...${NC}"

export DEBIAN_FRONTEND=noninteractive

run_with_spinner "Installing Redis Server" apt_install redis-server
run_with_spinner "Starting Redis service" bash -c "systemctl enable redis >/dev/null 2>&1 || true && systemctl restart redis"

echo -e "${GREEN}✅ Redis installed and running.${NC}"
