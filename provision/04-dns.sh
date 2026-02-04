#!/usr/bin/env bash
set -e

source /opt/nioxon/config/network.env

echo "🌐 Configuring captive DNS (LAN-only)"

# Ensure dnsmasq is installed
apt install -y dnsmasq

# Clean old config if exists
rm -f /etc/dnsmasq.d/nioxon.conf

# Write LAN-only dnsmasq config
cat > /etc/dnsmasq.d/nioxon.conf <<EOF
# Listen only on LAN + loopback
interface=$LAN_IFACE
listen-address=127.0.0.1,$LAN_IP
bind-interfaces

# Upstream DNS (for server + forwarding)
server=8.8.8.8
server=1.1.1.1

# Captive DNS for LAN users
address=/#/$LAN_IP
EOF

systemctl restart dnsmasq
systemctl enable dnsmasq

echo "✅ Captive DNS configured (server internet safe)"
