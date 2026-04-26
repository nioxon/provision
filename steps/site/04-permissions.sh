#!/bin/bash
set -euo pipefail

# Terminal Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Error: Setting permissions must be run as root. Please use sudo.${NC}" >&2
   exit 1
fi

if [[ -z "${1:-}" ]]; then
  echo -e "${RED}Error: Domain name is required.${NC}" >&2
  exit 1
fi

DOMAIN="$1"
TARGET_DIR="/home/forge/$DOMAIN"

echo -e "${YELLOW}🔒 Setting permissions for ${BLUE}$DOMAIN${NC}..."

if [[ ! -d "$TARGET_DIR" ]]; then
  echo -e "${RED}Error: Directory $TARGET_DIR does not exist.${NC}" >&2
  exit 1
fi

if ! id "forge" >/dev/null 2>&1; then
  echo -e "${RED}Error: User 'forge' does not exist. Please ensure the server is fully provisioned first.${NC}" >&2
  exit 1
fi

chown -R forge:forge "$TARGET_DIR"

# Apply Laravel specific permissions only if directories exist
if [[ -d "$TARGET_DIR/storage" ]]; then
  chmod -R 775 "$TARGET_DIR/storage"
fi

if [[ -d "$TARGET_DIR/bootstrap/cache" ]]; then
  chmod -R 775 "$TARGET_DIR/bootstrap/cache"
fi

echo -e "${GREEN}✅ Permissions updated successfully.${NC}"
