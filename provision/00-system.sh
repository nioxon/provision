#!/usr/bin/env bash
set -e

# Fix time (signature depends on this)
timedatectl set-ntp true

# Ensure core trust packages
apt install -y ubuntu-keyring ca-certificates

# Clean broken metadata
rm -rf /var/lib/apt/lists/*

# Allow Ubuntu release metadata updates (important for 25.x)
apt update --allow-releaseinfo-change --allow-releaseinfo-change-suite

# Normal system upgrade
apt upgrade -y

# Base tools
apt install -y software-properties-common unzip zip curl
