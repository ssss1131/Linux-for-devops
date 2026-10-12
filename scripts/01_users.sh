#!/bin/bash

ROLE=$1

if [ "$(id -u)" != "0" ]; then
  echo "Run as root: sudo bash 01_users.sh web|app|db|ops"
  exit 1
fi

if [ "$ROLE" != "web" ] && [ "$ROLE" != "app" ] && [ "$ROLE" != "db" ] && [ "$ROLE" != "ops" ]; then
  echo "Usage: sudo bash 01_users.sh web|app|db|ops"
  exit 1
fi

echo "== Groups for people =="

for GROUP in nc-ttp-admin nc-ttp-deploy nc-ttp-audit nc-ttp-bot; do
  if ! getent group $GROUP > /dev/null; then
    groupadd $GROUP
    echo "  group $GROUP created"
  else
    echo "  group $GROUP exists"
  fi
done

echo "== Users for people =="

if ! id saulet > /dev/null 2>&1; then
  useradd -m -s /bin/bash -G nc-ttp-admin,sudo saulet
  echo "saulet:ChangeMe123" | chpasswd
  echo "  user saulet created (group nc-ttp-admin)"
else
  echo "  user saulet exists"
fi

if ! id deployer > /dev/null 2>&1; then
  useradd -m -s /bin/bash -G nc-ttp-deploy deployer
  echo "deployer:ChangeMe123" | chpasswd
  echo "  user deployer created (group nc-ttp-deploy)"
else
  echo "  user deployer exists"
fi

if ! id auditor > /dev/null 2>&1; then
  useradd -m -s /bin/bash -G nc-ttp-audit auditor
  echo "auditor:ChangeMe123" | chpasswd
  echo "  user auditor created (group nc-ttp-audit)"
else
  echo "  user auditor exists"
fi

if ! id automation_bot > /dev/null 2>&1; then
  useradd -m -s /bin/bash -G nc-ttp-bot,nc-ttp-deploy automation_bot
  echo "  user automation_bot created (groups nc-ttp-bot, nc-ttp-deploy)"
else
  echo "  user automation_bot exists"
fi

echo "== Service accounts for role $ROLE =="

if [ "$ROLE" = "web" ]; then
  if ! id www-data > /dev/null 2>&1; then
    useradd --system --no-create-home --shell /usr/sbin/nologin www-data
    echo "  service user www-data created"
  else
    echo "  service user www-data exists"
  fi
fi

if [ "$ROLE" = "app" ]; then
  if ! id nc-ttp > /dev/null 2>&1; then
    useradd --system --no-create-home --home-dir /var/lib/nc-ttp --shell /usr/sbin/nologin nc-ttp
    echo "  service user nc-ttp created"
  else
    echo "  service user nc-ttp exists"
  fi
fi

if [ "$ROLE" = "db" ]; then
  if ! id postgres > /dev/null 2>&1; then
    useradd --system --no-create-home --home-dir /var/lib/postgresql --shell /usr/sbin/nologin postgres
    echo "  service user postgres created"
  else
    echo "  service user postgres exists"
  fi
fi

if [ "$ROLE" = "ops" ]; then
  if ! id prometheus > /dev/null 2>&1; then
    useradd --system --no-create-home --home-dir /var/lib/nc-ttp/prometheus --shell /usr/sbin/nologin prometheus
    echo "  service user prometheus created"
  else
    echo "  service user prometheus exists"
  fi
  if ! id grafana > /dev/null 2>&1; then
    useradd --system --no-create-home --home-dir /var/lib/nc-ttp/grafana --shell /usr/sbin/nologin grafana
    echo "  service user grafana created"
  else
    echo "  service user grafana exists"
  fi
fi

echo
echo "== Result on $(hostname) =="
echo "Groups:"
getent group nc-ttp-admin nc-ttp-deploy nc-ttp-audit nc-ttp-bot
echo "Users:"
id saulet
id deployer
id auditor
id automation_bot
echo "Users and groups for role $ROLE are ready"
