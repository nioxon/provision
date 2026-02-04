#!/usr/bin/env bash
set -e
source /opt/nioxon/config/network.env

echo "🌐 Configuring DNS (dnsmasq captive mode)"

# Stop systemd-resolved safely
systemctl stop systemd-resolved || true
systemctl disable systemd-resolved || true

# Remove resolv.conf immutability if exists
chattr -i /etc/resolv.conf 2>/dev/null || true

# Remove symlink or old file
rm -f /etc/resolv.conf

# Create clean resolv.conf
cat > /etc/resolv.conf <<EOF
nameserver 127.0.0.1
EOF

# Lock it
chattr +i /etc/resolv.conf

# Install dnsmasq
apt install -y dnsmasq

# Write dnsmasq config
cat > /etc/dnsmasq.d/nioxon.conf <<EOF
port=53
listen-address=127.0.0.1,$SERVER_IP
bind-interfaces

# Captive DNS: redirect ALL domains
address=/#/$SERVER_IP
EOF

systemctl restart dnsmasq
systemctl enable dnsmasq

echo "✅ DNS captive configuration completed"
