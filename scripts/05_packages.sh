#!/bin/bash

ROLE=$1

if [ "$(id -u)" != "0" ]; then
  echo "Run as root: sudo bash 05_packages.sh web|app|db|ops"
  exit 1
fi

if [ "$ROLE" != "web" ] && [ "$ROLE" != "app" ] && [ "$ROLE" != "db" ] && [ "$ROLE" != "ops" ]; then
  echo "Usage: sudo bash 05_packages.sh web|app|db|ops"
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive

echo "== 1. Packages from default repositories =="

apt-get update -q
apt-get install -yq net-tools netcat-openbsd ufw

if [ "$ROLE" = "web" ]; then
  apt-get install -yq nginx
  echo "  nginx installed"
fi

if [ "$ROLE" = "app" ]; then
  apt-get install -yq python3-pip
  echo "  python3-pip installed"
fi

if [ "$ROLE" = "db" ]; then
  apt-get install -yq postgresql
  echo "  postgresql installed"

  PGDIR=$(ls -d /etc/postgresql/*/main | head -n 1)
  if [ -n "$PGDIR" ]; then
    sed -i "s/^#*listen_addresses.*/listen_addresses = '*'/" $PGDIR/postgresql.conf
    if ! grep -q "192.168.56.11" $PGDIR/pg_hba.conf; then
      echo "host all all 192.168.56.11/32 scram-sha-256" >> $PGDIR/pg_hba.conf
    fi
    systemctl restart postgresql
    echo "  postgresql listens on the network, app is allowed"
  fi
fi

if [ "$ROLE" = "ops" ]; then
  apt-get install -yq prometheus-node-exporter
  echo "  prometheus-node-exporter installed"
fi

echo "== 2. Package from a new repository (git-core PPA) =="

if ! grep -rq git-core /etc/apt/sources.list.d 2>/dev/null; then
  apt-get install -yq software-properties-common
  add-apt-repository -y ppa:git-core/ppa
  apt-get update -q
  apt-get install -yq git
  echo "  git installed from ppa:git-core/ppa"
else
  echo "  git-core repository already added"
fi

echo "== 3. Package without a package manager (yq binary) =="

if ! command -v yq > /dev/null; then
  curl -fsSL -o /tmp/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
  install -o root -g root -m 755 /tmp/yq /usr/local/bin/yq
  rm -f /tmp/yq
  echo "  yq installed to /usr/local/bin"
else
  echo "  yq already installed"
fi

echo
echo "== Result on $(hostname) =="
echo "PATH = $PATH"
git --version
yq --version
apt-cache policy git | head -n 3
echo "Packages for role $ROLE are ready"
