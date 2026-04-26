#!/bin/bash

set -euo pipefail

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

function run_core_script() {
  local script_name="$1"
  local script_path="$PROJECT_ROOT/core/${script_name}.sh"
  shift

  if [[ ! -f "$script_path" ]]; then
    echo -e "${RED}Error: Core script '${script_name}' not found at ${script_path}${NC}" >&2
    exit 1
  fi

  bash "$script_path" "$@"
}

function print_logo() {
  echo -e "${CYAN}${BOLD}"
  echo '    _   ___           ____  __           '
  echo '   / | / (_)___  _  _/ __ \/ /___ ___  __'
  echo '  /  |/ / / __ \| |/_/ /_/ / / __ `/ / / /'
  echo ' / /|  / / /_/ />  </ ____/ / /_/ / /_/ / '
  echo '/_/ |_/_/\____/_/|_/_/   /_/\__,_/\__, /  '
  echo '                                 /____/   '
  echo -e "${NC}"
  echo -e "${DIM}  Enterprise Provisioning & Captive Portal CLI${NC}\n"
}

case "${1:-}" in
  provision)
    run_core_script "provision" "${@:2}"
    ;;
  site:create)
    run_core_script "site-create" "${@:2}"
    ;;
  site:bulk)
    run_core_script "site-bulk" "${@:2}"
    ;;
  site:list)
    run_core_script "site-list" "${@:2}"
    ;;
  site:update-all)
    run_core_script "site-update-all" "${@:2}"
    ;;
  wifi:api)
    run_core_script "wifi-api" "${@:2}"
    ;;
  self-update)
    run_core_script "self-update" "${@:2}"
    ;;
  ssl:renew)
    run_core_script "ssl-renew" "${@:2}"
    ;;
  captive:install)
    run_core_script "captive-install" "${@:2}"
    ;;
  *)
    print_logo
    echo -e "${BOLD}USAGE:${NC} nioxplay <command> [options]\n"
    echo -e "${BOLD}SERVER PROVISIONING${NC}"
    echo -e "  ${GREEN}provision${NC}         Provision the bare-metal server environment"
    echo -e "\n${BOLD}SITE MANAGEMENT${NC}"
    echo -e "  ${GREEN}site:create${NC}       Create and configure a single new site"
    echo -e "  ${GREEN}site:bulk${NC}         Bulk create sites from a domain list & fixed repo"
    echo -e "  ${GREEN}site:list${NC}         View an interactive table of all installed sites"
    echo -e "  ${GREEN}site:update-all${NC}   Pull latest code from GitHub for all sites"
    echo -e "\n${BOLD}SECURITY & NETWORKING${NC}"
    echo -e "  ${GREEN}ssl:renew${NC}         Renew Let's Encrypt certificates securely"
    echo -e "  ${GREEN}captive:install${NC}   Install and configure the offline captive portal"
    echo -e "\n${BOLD}SYSTEM MAINTENANCE${NC}"
    echo -e "  ${GREEN}wifi:api${NC}          JSON API for managing WiFi connections"
    echo -e "  ${GREEN}self-update${NC}       Update the NioxPlay CLI to the latest version\n"
    exit 1
    ;;
esac