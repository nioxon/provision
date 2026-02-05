#!/usr/bin/env bash
set -e
source /opt/nioxon/config/runtime.env

apt install -y dnsmasq

cat > /etc/dnsmasq.d/nioxon.conf <<EOF
interface=${LAN_IFACE}
bind-interfaces
listen-address=${LAN_IP}

domain-needed
bogus-priv

server=8.8.8.8
server=1.1.1.1

address=/#/${LAN_IP}
EOF

systemctl restart dnsmasq
systemctl enable dnsmasq
