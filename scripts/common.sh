#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

timedatectl set-timezone Asia/Almaty

if ! grep -q nc-ttp-web /etc/hosts; then
cat >> /etc/hosts <<EOF
192.168.56.10 nc-ttp-web
192.168.56.11 nc-ttp-app
192.168.56.12 nc-ttp-db
192.168.56.13 nc-ttp-ops
EOF
  echo "hosts updated"
fi

apt-get update -q
apt-get upgrade -yq
apt-get install -yq curl wget vim htop tree git unzip jq net-tools

echo "Base setup done on $(hostname)"
