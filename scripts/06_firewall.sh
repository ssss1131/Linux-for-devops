#!/bin/bash

ROLE=$1

if [ "$(id -u)" != "0" ]; then
  echo "Run as root: sudo bash 06_firewall.sh web|app|db|ops"
  exit 1
fi

if [ "$ROLE" != "web" ] && [ "$ROLE" != "app" ] && [ "$ROLE" != "db" ] && [ "$ROLE" != "ops" ]; then
  echo "Usage: sudo bash 06_firewall.sh web|app|db|ops"
  exit 1
fi

WEB=192.168.56.10
APP=192.168.56.11
DB=192.168.56.12
OPS=192.168.56.13

echo "== Default policy =="

ufw --force reset > /dev/null
ufw default deny incoming
ufw default allow outgoing

echo "== SSH for everybody =="

ufw allow 22/tcp comment "ssh"

if [ "$ROLE" = "web" ]; then
  echo "== Web rules =="
  ufw allow 80/tcp comment "http"
  ufw allow 443/tcp comment "https"
  ufw allow from $OPS to any port 9100 proto tcp comment "metrics from ops"
fi

if [ "$ROLE" = "app" ]; then
  echo "== App rules =="
  ufw allow from $WEB to any port 8080 proto tcp comment "api from web"
  ufw allow from $OPS to any port 8080 proto tcp comment "metrics from ops"
fi

if [ "$ROLE" = "db" ]; then
  echo "== DB rules =="
  ufw allow from $APP to any port 5432 proto tcp comment "postgres from app"
  ufw allow from $OPS to any port 9100 proto tcp comment "metrics from ops"
fi

if [ "$ROLE" = "ops" ]; then
  echo "== Ops rules =="
  ufw allow 3000/tcp comment "grafana"
  ufw allow 9090/tcp comment "prometheus"
fi

echo "== Enable firewall =="

ufw --force enable

echo
echo "== Result on $(hostname) =="
ufw status numbered
echo "Firewall for role $ROLE is ready"
