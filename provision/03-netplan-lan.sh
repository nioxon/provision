#!/usr/bin/env bash
set -e

source /opt/nioxon/config/network.env

echo "🔧 Applying LAN netplan (Wi-Fi safe mode)"

# Write netplan ONLY for LAN
cat > /etc/netplan/50-nioxon.yaml <<EOF
network:
  version: 2
  renderer: networkd
  ethernets:
    $LAN_IFACE:
      dhcp4: false
      addresses:
        - $LAN_IP/$LAN_NETMASK
      nameservers:
        addresses:
          - 127.0.0.1
EOF

# Generate + apply netplan
netplan generate
netplan apply

# 🔴 CRITICAL FIX: force NetworkManager to reconnect Wi-Fi
echo "🔄 Reconnecting Wi-Fi after netplan apply"

systemctl restart NetworkManager

sleep 5

# Try reconnecting Wi-Fi automatically
nmcli device set "$WIFI_IFACE" managed yes || true
nmcli device connect "$WIFI_IFACE" || true

echo "✅ LAN netplan applied without breaking Wi-Fi"
