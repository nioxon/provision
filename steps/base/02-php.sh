#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_ROOT/core/utils.sh"

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Error: PHP setup must be run as root. Please use sudo.${NC}" >&2
   exit 1
fi

echo -e "${YELLOW}🐘 Installing PHP 8.3 and extensions...${NC}"

export DEBIAN_FRONTEND=noninteractive

run_with_spinner "Adding PHP repository (ppa:ondrej/php)" bash -c "add-apt-repository ppa:ondrej/php -y >/dev/null 2>&1 && apt_update"
run_with_spinner "Installing PHP packages" apt_install php8.3 php8.3-fpm php8.3-cli php8.3-mysql php8.3-curl php8.3-mbstring php8.3-xml php8.3-bcmath php8.3-zip
run_with_spinner "Starting PHP-FPM service" bash -c "systemctl enable php8.3-fpm >/dev/null 2>&1 && systemctl restart php8.3-fpm"

echo -e "\n${YELLOW}📦 Installing Composer...${NC}"
run_with_spinner "Downloading and setting up Composer" bash -c "curl -sS https://getcomposer.org/installer | php >/dev/null 2>&1 && mv composer.phar /usr/local/bin/composer && chmod +x /usr/local/bin/composer"

echo -e "${GREEN}✅ PHP and Composer installed successfully.${NC}"
