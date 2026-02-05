#!/usr/bin/env bash
set -e

echo "▶ Base system preparation"

# ---------------------------------------
# 1. Ensure time sync (safe to repeat)
# ---------------------------------------
timedatectl set-ntp true || true

# ---------------------------------------
# 2. Ensure trust packages (idempotent)
# ---------------------------------------
apt-get update -qq || true
apt-get install -y ubuntu-keyring ca-certificates

# ---------------------------------------
# 3. Fix broken apt state (SAFE)
# ---------------------------------------
dpkg --configure -a || true
apt-get install -f -y || true

# ---------------------------------------
# 4. Update package index (SAFE MODE)
# ---------------------------------------
if ! apt-get update; then
  echo "⚠ apt update failed, retrying with release-info change"
  apt-get update --allow-releaseinfo-change --allow-releaseinfo-change-suite
fi

# ---------------------------------------
# 5. DO NOT FULL UPGRADE ON RE-RUNS
# ---------------------------------------
# Upgrade only if this is first run
if [ ! -f /opt/nioxon/.system-upgraded ]; then
  echo "▶ Performing one-time system upgrade"
  apt-get upgrade -y
  touch /opt/nioxon/.system-upgraded
else
  echo "✔ System already upgraded (skipped)"
fi

# ---------------------------------------
# 6. Base packages (idempotent)
# ---------------------------------------
apt-get install -y \
  software-properties-common \
  unzip \
  zip \
  curl

echo "✔ Base system ready"
