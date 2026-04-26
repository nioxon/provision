#!/bin/bash
set -euo pipefail

# Terminal Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Error: Git deploy must be run as root. Please use sudo.${NC}" >&2
   exit 1
fi

if [[ $# -lt 2 ]]; then
  echo -e "${RED}Error: Missing arguments. Usage: 03-git-deploy.sh <domain> <repo_url>${NC}" >&2
  exit 1
fi

DOMAIN="$1"
REPO="$2"
TARGET_DIR="/home/forge/$DOMAIN"

echo -e "${YELLOW}📦 Deploying repository for ${BLUE}$DOMAIN${NC}..."

cd "$TARGET_DIR"

# Prevent SSH from hanging on the "authenticity of host can't be established" prompt
export GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=no"

# Prevent "dubious ownership" errors when root pulls a repo owned by forge
git config --global --add safe.directory "$TARGET_DIR"

if [[ -d ".git" ]]; then
  echo -e "Repository already exists. Pulling latest changes..."
  git stash -q || true
  git pull -q
else
  echo -e "Cloning repository..."
  git clone -q "$REPO" .
fi

if [[ ! -f ".env" && -f ".env.example" ]]; then
  echo -e "Copying .env.example to .env..."
  cp .env.example .env
fi

if [[ -f "composer.json" ]]; then
  echo -e "Installing Composer dependencies..."
  export COMPOSER_ALLOW_SUPERUSER=1
  composer install --no-dev --optimize-autoloader --quiet
fi

if [[ -f "artisan" ]]; then
  echo -e "Generating application key..."
  php artisan key:generate --force >/dev/null 2>&1 || true
  echo -e "Optimizing Laravel caching..."
  php artisan optimize:clear >/dev/null 2>&1 || true
fi

echo -e "${GREEN}✅ Deployment completed for ${BLUE}$DOMAIN${NC}"
