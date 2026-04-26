#!/bin/bash
set -euo pipefail

# Terminal Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Error: Database creation must be run as root. Please use sudo.${NC}" >&2
   exit 1
fi

if [[ -z "${1:-}" ]]; then
  echo -e "${RED}Error: Domain name is required.${NC}" >&2
  exit 1
fi

DOMAIN="$1"
DB_NAME=$(echo "$DOMAIN" | tr '.' '_')

echo -e "${YELLOW}🗄️ Creating database: ${BLUE}$DB_NAME${NC}"

mysql -e "CREATE DATABASE IF NOT EXISTS \`$DB_NAME\`;"
echo -e "${GREEN}✅ Database created successfully.${NC}"
