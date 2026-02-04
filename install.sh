#!/usr/bin/env bash
set -e

BASE_DIR="/opt/nioxon"
CONFIG_DIR="$BASE_DIR/config"
RUNTIME_ENV="$CONFIG_DIR/runtime.env"
PROVISION_DIR="$BASE_DIR/provision"

mkdir -p "$CONFIG_DIR"

# -------------------------
# UI HELPERS
# -------------------------
green() { echo -e "\033[32m$1\033[0m"; }
red()   { echo -e "\033[31m$1\033[0m"; }
yellow(){ echo -e "\033[33m$1\033[0m"; }
bold()  { echo -e "\033[1m$1\033[0m"; }

run_step() {
  local step="$1"
  local label="$2"

  printf "[%s] %-30s" "$step" "$label"
  if bash "$PROVISION_DIR/$step.sh" >/dev/null 2>&1; then
    green "✔ Done"
  else
    red "✖ Failed"
    exit 1
  fi
}

require_internet() {
  if ! ping -c1 8.8.8.8 >/dev/null 2>&1; then
    red "❌ Internet not available. Fix Wi-Fi and retry."
    exit 1
  fi
}

# -------------------------
# HARDWARE DETECTION
# -------------------------
detect_wifi_iface() {
  nmcli -t -f DEVICE,TYPE device | awk -F: '$2=="wifi"{print $1; exit}'
}

detect_lan_iface() {
  nmcli -t -f DEVICE,TYPE device | awk -F: '$2=="ethernet"{print $1; exit}'
}

# -------------------------
# COMMANDS
# -------------------------

doctor() {
  bold "🩺 NIOXON Doctor"
  echo ""

  echo "OS: $(lsb_release -ds 2>/dev/null || echo Unknown)"
  echo "Kernel: $(uname -r)"
  echo "CPU: $(nproc) cores"
  echo "RAM: $(free -h | awk '/Mem:/ {print $2}')"
  echo ""

  LAN_IFACE=$(detect_lan_iface)
  WIFI_IFACE=$(detect_wifi_iface)

  if [ -n "$LAN_IFACE" ]; then
    green "✔ LAN Interface: $LAN_IFACE"
  else
    red "✖ No LAN interface detected"
  fi

  if [ -n "$WIFI_IFACE" ]; then
    green "✔ Wi-Fi Interface: $WIFI_IFACE"
  else
    red "✖ No Wi-Fi adapter detected"
  fi

  if ping -c1 8.8.8.8 >/dev/null 2>&1; then
    green "✔ Internet: Connected"
  else
    yellow "⚠ Internet: Not connected"
    echo "  → Run: nioxon wifi"
  fi
}

wifi() {
  bold "📡 Wi-Fi Setup"
  echo ""

  WIFI_IFACE=$(detect_wifi_iface)

  if [ -z "$WIFI_IFACE" ]; then
    red "No Wi-Fi adapter found"
    exit 1
  fi

  echo "Detected Wi-Fi device: $WIFI_IFACE"
  echo ""

  if nmcli -t -f DEVICE,STATE device | grep "^$WIFI_IFACE:connected" >/dev/null; then
    green "✔ Already connected to Wi-Fi"
    return
  fi

  nmcli device wifi list ifname "$WIFI_IFACE"
  echo ""
  read -p "Enter SSID: " SSID
  read -s -p "Enter Wi-Fi password: " PASS
  echo ""

  echo "Connecting..."
  if nmcli device wifi connect "$SSID" password "$PASS" ifname "$WIFI_IFACE"; then
    green "✔ Connected to $SSID"
  else
    red "✖ Failed to connect"
    exit 1
  fi

  require_internet
  green "✔ Internet reachable"
}

configure() {
  bold "⚙️ NIOXON Configuration"
  echo ""

  LAN_IFACE=$(detect_lan_iface)
  WIFI_IFACE=$(detect_wifi_iface)

  read -p "Project name [nioxon]: " PROJECT_NAME
  PROJECT_NAME=${PROJECT_NAME:-nioxon}

  read -p "Domain [nioxplay.local]: " SITE_DOMAIN
  SITE_DOMAIN=${SITE_DOMAIN:-nioxplay.local}

  read -p "LAN interface [$LAN_IFACE]: " INPUT_LAN
  LAN_IFACE=${INPUT_LAN:-$LAN_IFACE}

  read -p "LAN IP [192.168.1.2]: " LAN_IP
  LAN_IP=${LAN_IP:-192.168.1.2}

  read -p "LAN subnet [24]: " LAN_NETMASK
  LAN_NETMASK=${LAN_NETMASK:-24}

  cat > "$RUNTIME_ENV" <<EOF
PROJECT_NAME=$PROJECT_NAME
SITE_DOMAIN=$SITE_DOMAIN
LAN_IFACE=$LAN_IFACE
LAN_IP=$LAN_IP
LAN_NETMASK=$LAN_NETMASK
WIFI_IFACE=$WIFI_IFACE
EOF

  green "✔ Configuration saved"
}

install() {
  bold "🚀 NIOXON Provisioning"
  echo ""

  if [ ! -f "$RUNTIME_ENV" ]; then
    yellow "Configuration missing"
    echo "Run: nioxon configure"
    exit 1
  fi

  source "$RUNTIME_ENV"

  require_internet

  run_step "00" "System update"
  run_step "01" "Security setup"
  run_step "02" "NetworkManager"
  run_step "03" "Nginx"
  run_step "04" "PHP"
  run_step "05" "MySQL"
  run_step "06" "Node.js"
  run_step "07" "Redis"
  run_step "08" "Supervisor"

  echo ""
  yellow "⚠ Applying LAN & captive network (internet no longer required)"

  run_step "11" "LAN netplan"
  run_step "12" "Captive DNS"
  run_step "13" "Captive redirect"

  echo ""
  green "🎉 Provisioning completed"
  echo "Access: http://$SITE_DOMAIN"
}

# -------------------------
# ROUTER
# -------------------------
case "$1" in
  doctor) doctor ;;
  wifi) wifi ;;
  configure) configure ;;
  install) install ;;
  *)
    echo "NIOXON CLI"
    echo ""
    echo "Usage:"
    echo "  nioxon doctor     # system check"
    echo "  nioxon wifi       # connect Wi-Fi"
    echo "  nioxon configure  # set variables"
    echo "  nioxon install    # provision server"
    ;;
esac
