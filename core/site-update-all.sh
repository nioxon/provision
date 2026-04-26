#!/bin/bash
set -euo pipefail

# Terminal Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Error: Updating sites must be run as root. Please use sudo.${NC}" >&2
   exit 1
fi

echo -e "\n${YELLOW}🔄 Updating all NioxPlay Sites from GitHub...${NC}"
echo -e "${YELLOW}--------------------------------------------${NC}"

shopt -s nullglob
SITES=( /home/forge/* )
TOTAL_SITES=0
for s in "${SITES[@]}"; do [[ -d "$s/.git" ]] && TOTAL_SITES=$((TOTAL_SITES+1)); done

CURRENT_SITE=0

for site_dir in "${SITES[@]}"; do
  if [[ -d "$site_dir/.git" ]]; then
    CURRENT_SITE=$((CURRENT_SITE+1))
    PERCENTAGE=$((CURRENT_SITE * 100 / TOTAL_SITES))
    WIDTH=40
    COMP=$((WIDTH * CURRENT_SITE / TOTAL_SITES))
    REM=$((WIDTH - COMP))

    DOMAIN=$(basename "$site_dir")
    
    echo -e "\n${BLUE}======================================================${NC}"
    printf "${BOLD}${CYAN}⌛ UPDATE PROGRESS: [${GREEN}%s${NC}${DIM}%s${NC}${BOLD}${CYAN}] %3d%%${NC}\n" \
      "$(printf "%${COMP}s" | tr ' ' '█')" \
      "$(printf "%${REM}s" | tr ' ' '░')" \
      "$PERCENTAGE"
    echo -e "${BOLD}▶ Updating $DOMAIN...${NC}"
    echo -e "${BLUE}======================================================${NC}"
    
    cd "$site_dir"
    
    # Prevent SSH from hanging on the host check prompt
    export GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=no"

    # Prevent "dubious ownership" errors
    git config --global --add safe.directory "$site_dir"

    echo -e "Pulling latest changes..."
    git stash -q || true
    git pull -q

    if [[ -f "composer.json" ]]; then
      echo -e "Installing Composer dependencies..."
      export COMPOSER_ALLOW_SUPERUSER=1
      composer install --no-dev --optimize-autoloader --quiet
    fi
    
    if [[ -f "artisan" ]]; then
      php artisan optimize:clear >/dev/null 2>&1 || true
    fi
    
    # Ensure permissions remain correct after pulling new files
    chown -R forge:forge "$site_dir"
    
    echo -e "${GREEN}✅ $DOMAIN updated.${NC}"
  fi
done
shopt -u nullglob

echo -e "\n${GREEN}✅ All sites updated successfully!${NC}"