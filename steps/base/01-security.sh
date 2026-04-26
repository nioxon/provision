#!/bin/bash
set -euo pipefail

# Terminal Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

if [[ -f "$PROJECT_ROOT/config.env" ]]; then
  source "$PROJECT_ROOT/config.env"
fi

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Error: Security setup must be run as root. Please use sudo.${NC}" >&2
   exit 1
fi

echo -e "${YELLOW}🔒 Configuring security and creating 'forge' user...${NC}"

# Check if forge user exists, create if not
if id "forge" >/dev/null 2>&1; then
  echo -e "${BLUE}User 'forge' already exists. Skipping creation.${NC}"
else
  echo -e "Creating 'forge' user..."
  # Create the user with a home directory and bash as the default shell
  useradd -m -s /bin/bash forge
  
  # Setup passwordless sudo for forge
  echo "forge ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/99-forge-user
  chmod 0440 /etc/sudoers.d/99-forge-user
fi

# Generate SSH key for the server (root user) to pull private repos
if [[ ! -f /root/.ssh/id_ed25519 ]]; then
  echo -e "Generating SSH key for private GitHub access..."
  ssh-keygen -t ed25519 -C "nioxplay-server" -f /root/.ssh/id_ed25519 -N "" -q
  
  # Auto-upload to GitHub if token exists
  UPLOAD_SUCCESS=false

  if [[ -n "${GITHUB_PAT:-}" ]]; then
    echo -e "Uploading SSH key to GitHub using token from config.env..."
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X POST \
      -H "Accept: application/vnd.github+json" \
      -H "Authorization: Bearer $GITHUB_PAT" \
      -H "X-GitHub-Api-Version: 2022-11-28" \
      https://api.github.com/user/keys \
      -d "{\"title\":\"NioxPlay Server $(hostname)\",\"key\":\"$(cat /root/.ssh/id_ed25519.pub)\"}")

    if [[ "$HTTP_STATUS" == "201" ]]; then
      echo -e "${GREEN}✅ SSH key successfully added to your GitHub account!${NC}"
      UPLOAD_SUCCESS=true
    else
      echo -e "${RED}❌ Failed to upload SSH key to GitHub (HTTP $HTTP_STATUS). Please check your token.${NC}"
    fi
  fi

  if [[ "$UPLOAD_SUCCESS" == false ]]; then
    echo -e "\n${YELLOW}======================================================${NC}"
    echo -e "${GREEN}Here is your Server's Public SSH Key:${NC}"
    cat /root/.ssh/id_ed25519.pub
    echo -e "${GREEN}Add this to your GitHub account manually (Settings -> SSH Keys)${NC}"
    echo -e "${YELLOW}======================================================\n${NC}"
  fi
fi

echo -e "${GREEN}✅ Security setup completed.${NC}"