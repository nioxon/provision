#!/usr/bin/env bash
set -e

apt update -y
apt install -y \
  curl \
  git \
  ca-certificates \
  lsb-release \
  software-properties-common
