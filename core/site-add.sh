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

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Error: Site creation must be run as root. Please use sudo.${NC}" >&2
   exit 1
fi

function run_step() {
  local step_file="$1"
  shift # Shift the first argument out so we can pass the rest to the script
  local step_path="$PROJECT_ROOT/$step_file"

  if [[ ! -f "$step_path" ]]; then
    echo -e "${RED}Error: Step script not found at ${step_path}${NC}" >&2
    exit 1
  fi

  bash "$step_path" "$@"
}

DOMAIN=${1:-}
BIND_IP=${2:-}
TYPE=${3:-}
REPO=${4:-}
SSL_CHOICE=${5:-}
LE_EMAIL=${6:-}
FORMAT=${7:-text}

if [[ "$FORMAT" != "json" ]]; then
  echo -e "\n${BLUE}======================================================${NC}"
  echo -e "${BOLD}🌍 CREATE NEW SITE${NC}"
  echo -e "${BLUE}======================================================${NC}\n"
else
  # Save stdout to file descriptor 3, then redirect stdout to /dev/null
  exec 3>&1
  exec 1>/dev/null
fi

# Fallback to interactive mode if domain is not provided via arguments
if [[ -z "$DOMAIN" ]]; then
  read -r -p "$(echo -e "${BOLD}Enter Domain Name:${NC} ")" DOMAIN
  read -r -p "$(echo -e "${BOLD}Bind IP Address${NC} (example 10.10.10.3): ")" BIND_IP
  read -r -p "$(echo -e "${BOLD}Type${NC} (html/laravel): ")" TYPE
  read -r -p "$(echo -e "${BOLD}GitHub Repo URL${NC} (optional): ")" REPO
  echo -e "\n${BOLD}SSL Options:${NC}"
  echo -e "  [1] None"
  echo -e "  [2] Self-Signed (Local warning)"
  echo -e "  [3] Let's Encrypt (Requires Real Domain & Cloudflare API)"
  read -r -p "$(echo -e "${BOLD}Select SSL [1-3]:${NC} ")" SSL_CHOICE

  if [[ "$SSL_CHOICE" == "3" ]]; then
    read -r -p "$(echo -e "${BOLD}Enter Admin Email for Let's Encrypt:${NC} ")" LE_EMAIL
  fi
fi

# Set defaults if missing
BIND_IP=${BIND_IP:-10.10.10.3}
TYPE=${TYPE:-laravel}
SSL_CHOICE=${SSL_CHOICE:-1}

run_step "steps/site/01-db-create.sh" "$DOMAIN"
run_step "steps/site/02-nginx-vhost.sh" "$DOMAIN" "$TYPE" "$BIND_IP"

if [[ "$SSL_CHOICE" == "2" ]]; then
  run_step "steps/site/05-ssl.sh" "$DOMAIN"
elif [[ "$SSL_CHOICE" == "3" ]]; then
  run_step "steps/site/06-letsencrypt-dns.sh" "$DOMAIN" "$LE_EMAIL"
fi

if [[ -n "$REPO" ]]; then
  run_step "steps/site/03-git-deploy.sh" "$DOMAIN" "$REPO"
  run_step "steps/site/04-permissions.sh" "$DOMAIN"
fi

if [[ "$FORMAT" == "json" ]]; then
  # Restore stdout and print strict JSON
  exec 1>&3
  SECURE="false"
  [[ "$SSL_CHOICE" -ge 2 ]] && SECURE="true"
  printf '{"status":"success","domain":"%s","ip":"%s","secure":%s}\n' "$DOMAIN" "$BIND_IP" "$SECURE"
else
  echo -e "\n${GREEN}${BOLD}✅ Site Created Successfully!${NC}"
  echo -e "${BLUE}------------------------------------------------------${NC}"
  echo -e "Bound to IP: ${BLUE}http://$BIND_IP${NC}"
  echo -e "Domain: ${BLUE}http://$DOMAIN${NC}"
  [[ "$SSL_CHOICE" -ge 2 ]] && echo -e "Secure:      ${BLUE}https://$DOMAIN${NC}"
  echo -e "${BLUE}------------------------------------------------------${NC}\n"
fi
