#!/usr/bin/env bash
set -e
source /opt/nioxon/config/runtime.env

echo "▶ Configuring DNSMasq (Captive DNS)"

apt install -y dnsmasq

# Disable systemd-resolved DNS conflict (safe for captive systems)
systemctl disable systemd-resolved --now || true

# Ensure resolv.conf points to local DNS
rm -f /etc/resolv.conf
echo "nameserver 127.0.0.1" > /etc/resolv.conf

cat > /etc/dnsmasq.d/nioxon.conf <<EOF
# Bind to LAN only
interface=${LAN_IFACE}
bind-interfaces
listen-address=${LAN_IP}

# Basic DNS safety
domain-needed
bogus-priv
no-resolv

# Upstream DNS (only used if allowed later)
server=8.8.8.8
server=1.1.1.1

# ---- CRITICAL PART ----
# App domain (must be FIRST)
address=/${SITE_DOMAIN}/${LAN_IP}

# Captive fallback (everything else)
address=/#/${LAN_IP}
EOF

systemctl restart dnsmasq
systemctl enable dnsmasq

echo "✔ DNSMasq configured successfully"
