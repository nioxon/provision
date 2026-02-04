#!/usr/bin/env bash
set -e
apt update
apt upgrade -y
apt install -y software-properties-common curl git unzip ca-certificates
