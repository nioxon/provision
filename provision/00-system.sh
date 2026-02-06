#!/usr/bin/env bash
set -e

export DEBIAN_FRONTEND=noninteractive

apt update -y
apt upgrade -y

apt install -y \
  ca-certificates \
  curl \
  wget \
  unzip \
  zip \
  jq \
  gnupg \
  lsb-release \
  software-properties-common
