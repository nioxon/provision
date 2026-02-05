#!/usr/bin/env bash
set -e
source /opt/nioxon/config/runtime.env

cat > /etc/netplan/50-nioxon-lan.yaml <<EOF
network:
  version: 2
  renderer: networkd
  ethernets:
    ${LAN_IFACE}:
      dhcp4: no
      addresses:
        - ${LAN_IP}/${LAN_NETMASK}
EOF

netplan generate
netplan apply
