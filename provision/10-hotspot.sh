#!/usr/bin/env bash
set -e
source /opt/nioxon/config/hotspot.env

echo "📡 Setting up Wi-Fi Hotspot on $WIFI_IFACE"

apt install -y hostapd iw

systemctl stop hostapd || true

# hostapd config
cat > /etc/hostapd/hostapd.conf <<EOF
interface=$WIFI_IFACE
driver=nl80211
ssid=$HOTSPOT_SSID
hw_mode=g
channel=$HOTSPOT_CHANNEL
ieee80211n=1
wmm_enabled=1
auth_algs=1
ignore_broadcast_ssid=0
wpa=0
EOF

# bind config
sed -i 's|#DAEMON_CONF=.*|DAEMON_CONF="/etc/hostapd/hostapd.conf"|' /etc/default/hostapd

systemctl unmask hostapd
systemctl enable hostapd
