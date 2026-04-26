#!/bin/bash

# Global Terminal Colors
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export CYAN='\033[0;36m'
export BOLD='\033[1m'
export DIM='\033[2m'
export NC='\033[0m'

# Elite DevOps APT Wrappers (Zero Prompts)
function apt_update() {
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -qq -y
}

function apt_upgrade() {
  export DEBIAN_FRONTEND=noninteractive
  apt-get upgrade -qq -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"
}

function apt_install() {
  export DEBIAN_FRONTEND=noninteractive
  apt-get install -qq -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" "$@"
}

# Global Spinner Utility
function run_with_spinner() {
  local msg="$1"
  shift
  echo -n -e "${CYAN}▶ ${msg}... ${NC}"
  "$@" > /dev/null 2>&1 &
  local pid=$!
  local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
  while kill -0 $pid 2>/dev/null; do
    local temp=${spinstr#?}
    printf "${YELLOW}%c${NC}" "$spinstr"
    local spinstr=$temp${spinstr%"$temp"}
    sleep 0.1
    printf "\b"
  done
  wait $pid
  local status=$?
  if [[ $status -eq 0 ]]; then
    echo -e "${GREEN}✔ Done${NC}"
  else
    echo -e "${RED}✖ Failed${NC}"
    exit $status
  fi
}