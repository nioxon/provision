#!/bin/bash
set -euo pipefail

# Terminal Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

if [[ -f "$PROJECT_ROOT/config.env" ]]; then
  source "$PROJECT_ROOT/config.env"
fi

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Error: Bulk site creation must be run as root. Please use sudo.${NC}" >&2
   exit 1
fi

function run_step() {
  local step_file="$1"
  shift
  local step_path="$PROJECT_ROOT/$step_file"

  if [[ ! -f "$step_path" ]]; then
    echo -e "${RED}Error: Step script not found at ${step_path}${NC}" >&2
    exit 1
  fi

  bash "$step_path" "$@"
}

echo -e "\n${BLUE}======================================================${NC}"
echo -e "${BOLD}🌍 BULK SITE DEPLOYMENT${NC}"
echo -e "${BLUE}======================================================${NC}\n"

if [[ -n "${GITHUB_REPO_URL:-}" ]]; then
  FIXED_REPO="$GITHUB_REPO_URL"
  echo -e "Using fixed repository: ${BLUE}$FIXED_REPO${NC}"
else
  read -r -p "$(echo -e "${BOLD}Enter Fixed GitHub Repo URL:${NC} ")" FIXED_REPO
fi
read -r -p "$(echo -e "${BOLD}Enter Domains${NC} (space separated): ")" DOMAINS
read -r -p "$(echo -e "${BOLD}Bind IP Address${NC} (default 10.10.10.3): ")" BIND_IP
BIND_IP=${BIND_IP:-10.10.10.3}
read -r -p "$(echo -e "${BOLD}Type${NC} (html/laravel) [default: laravel]: ")" TYPE
TYPE=${TYPE:-laravel}

echo -e "\n${BOLD}SSL Options for all sites:${NC}"
echo -e "  [1] None"
echo -e "  [2] Self-Signed (Local warning)"
echo -e "  [3] Let's Encrypt (Requires Real Domain & Cloudflare API)"
read -r -p "$(echo -e "${BOLD}Select SSL [1-3]:${NC} ")" SSL_CHOICE

if [[ "$SSL_CHOICE" == "3" ]]; then
  read -r -p "$(echo -e "${BOLD}Enter Admin Email for Let's Encrypt:${NC} ")" LE_EMAIL
fi

TOTAL_DOMAINS=$(echo "$DOMAINS" | wc -w)

if [[ "$TOTAL_DOMAINS" -eq 0 ]]; then
  echo -e "${RED}❌ No domains provided. Exiting.${NC}" >&2
  exit 1
fi

CURRENT_DOMAIN=0

for DOMAIN in $DOMAINS; do
  CURRENT_DOMAIN=$((CURRENT_DOMAIN + 1))
  PERCENTAGE=$((CURRENT_DOMAIN * 100 / TOTAL_DOMAINS))
  WIDTH=40
  COMP=$((WIDTH * CURRENT_DOMAIN / TOTAL_DOMAINS))
  REM=$((WIDTH - COMP))

  echo -e "\n${BLUE}======================================================${NC}"
  printf "${BOLD}${CYAN}⌛ DEPLOY PROGRESS: [${GREEN}%s${NC}${DIM}%s${NC}${BOLD}${CYAN}] %3d%%${NC}\n" \
    "$(printf "%${COMP}s" | tr ' ' '█')" \
    "$(printf "%${REM}s" | tr ' ' '░')" \
    "$PERCENTAGE"
  echo -e "${BOLD}▶ Provisioning: ${DOMAIN} (${CURRENT_DOMAIN}/${TOTAL_DOMAINS})${NC}"
  echo -e "${BLUE}======================================================${NC}\n"
  
  run_step "steps/site/01-db-create.sh" "$DOMAIN"
  run_step "steps/site/02-nginx-vhost.sh" "$DOMAIN" "$TYPE" "$BIND_IP"
  
  if [[ "$SSL_CHOICE" == "2" ]]; then
    run_step "steps/site/05-ssl.sh" "$DOMAIN"
  elif [[ "$SSL_CHOICE" == "3" ]]; then
    run_step "steps/site/06-letsencrypt-dns.sh" "$DOMAIN" "$LE_EMAIL"
  fi
  
  if [[ -n "$FIXED_REPO" ]]; then
    run_step "steps/site/03-git-deploy.sh" "$DOMAIN" "$FIXED_REPO"
    run_step "steps/site/04-permissions.sh" "$DOMAIN"
  fi
  
  echo -e "${GREEN}✅ $DOMAIN provisioned successfully!${NC}"
done

echo -e "\n${GREEN}${BOLD}🎉 All sites successfully bulk deployed!${NC}\n"