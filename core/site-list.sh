#!/bin/bash
set -euo pipefail

# Terminal Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Error: Listing sites requires read access to Nginx configs. Please use sudo.${NC}" >&2
   exit 1
fi

echo -e "\n${BOLD}🌍 INSTALLED NIOXPLAY SITES${NC}"

echo -e "${BLUE}+------------------+------------------------------+------------------------------------------------+${NC}"
printf "${BLUE}| ${BOLD}%-16s${NC}${BLUE} | ${BOLD}%-28s${NC}${BLUE} | ${BOLD}%-46s${NC}${BLUE} |\n" "IP Address" "Domain Name" "Root Path"
echo -e "${BLUE}+------------------+------------------------------+------------------------------------------------+${NC}"

# Enable nullglob so the loop won't execute if the directory is empty
shopt -s nullglob
for file in /etc/nginx/sites-enabled/*; do
  [[ -f "$file" ]] || continue

  # Suppress pipefail crashes using || true in case a directive is missing
  IP=$(grep -m1 "listen" "$file" | awk '{print $2}' | cut -d: -f1 || true)
  DOMAIN=$(grep -m1 "server_name" "$file" | awk '{print $2}' | tr -d ';' || true)
  ROOT=$(grep -m1 "root" "$file" | awk '{print $2}' | tr -d ';' || true)

  if [[ -n "$DOMAIN" ]]; then
    printf "${BLUE}| ${NC}%-16s${BLUE} | ${NC}%-28s${BLUE} | ${NC}%-46s${BLUE} |\n" "$IP" "$DOMAIN" "$ROOT"
  fi
done
shopt -u nullglob

echo -e "${BLUE}+------------------+------------------------------+------------------------------------------------+${NC}"
echo -e "\n${GREEN}✅ Display completed.${NC}\n"
