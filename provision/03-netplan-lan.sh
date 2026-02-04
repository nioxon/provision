#!/usr/bin/env bash
set -e

source /opt/nioxon/config/network.env

# ---- VALIDATION (CRITICAL) ----
if [ -z "$LAN_IFACE" ] || [ -z "$LAN_IP" ] || [ -z "$LAN_NETMASK" ]; then
  echo "❌ network.env is incomplete"
  echo "LAN_IFACE=$LAN_IFACE"
  echo "LAN_IP=$LAN_IP"
  echo "LAN_NETMASK=$LAN_NETMASK"
  exit 1
fi

echo "📡 Configuring LAN interface: $LAN_IFACE ($LAN_IP/$LAN_NETMASK)"

# ---- WRITE NETPLAN ----
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

# ---- VALIDATE BEFORE APPLY ----
netplan generate
netplan apply
