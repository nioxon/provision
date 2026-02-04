#!/usr/bin/env bash
set -e
source /opt/nioxon/config/network.env

cat > /etc/netplan/50-nioxon.yaml <<EOF
network:
  version: 2
  renderer: networkd
  ethernets:
    $LAN_IFACE:
      dhcp4: no
      addresses:
        - $LAN_IP/$LAN_NETMASK
      nameservers:
        addresses:
          - 127.0.0.1
EOF

netplan generate
netplan apply
