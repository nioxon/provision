#!/usr/bin/env bash
set -e
source /opt/nioxon/config/hotspot.env
source /opt/nioxon/config/server.env

echo "🌐 Setting up DHCP & captive DNS"

apt install -y dnsmasq

systemctl stop dnsmasq || true

# Backup default config once
if [ ! -f /etc/dnsmasq.conf.orig ]; then
  mv /etc/dnsmasq.conf /etc/dnsmasq.conf.orig
fi

cat > /etc/dnsmasq.conf <<EOF
interface=$WIFI_IFACE
dhcp-range=$DHCP_START,$DHCP_END,$DHCP_LEASE

# Captive portal DNS (redirect everything)
address=/#/$HOTSPOT_IP
EOF

# Static IP for WiFi
cat > /etc/netplan/99-hotspot.yaml <<EOF
network:
  version: 2
  renderer: networkd
  ethernets: {}
  wifis:
    $WIFI_IFACE:
      dhcp4: no
      addresses:
        - $HOTSPOT_IP/$HOTSPOT_NETMASK
EOF

netplan apply

systemctl enable dnsmasq
systemctl start dnsmasq
systemctl start hostapd
