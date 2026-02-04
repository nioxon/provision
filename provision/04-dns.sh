#!/usr/bin/env bash
set -e
source /opt/nioxon/config/network.env

systemctl stop systemd-resolved || true
systemctl disable systemd-resolved || true

chattr -i /etc/resolv.conf 2>/dev/null || true
rm -f /etc/resolv.conf
echo "nameserver 127.0.0.1" > /etc/resolv.conf
chattr +i /etc/resolv.conf

apt install -y dnsmasq

cat > /etc/dnsmasq.d/nioxon.conf <<EOF
port=53
listen-address=127.0.0.1,$LAN_IP
bind-interfaces
address=/#/$LAN_IP
EOF

systemctl enable dnsmasq
systemctl restart dnsmasq
