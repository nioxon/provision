#!/usr/bin/env bash
set -e
source /opt/nioxon/config/runtime.env

NETPLAN_FILE="/etc/netplan/50-nioxon-lan.yaml"

cat > "$NETPLAN_FILE" <<EOF
network:
  version: 2
  renderer: NetworkManager
  ethernets:
    $LAN_IFACE:
      dhcp4: no
      addresses:
        - $LAN_IP/24
EOF

chmod 600 "$NETPLAN_FILE"

netplan generate
netplan apply
