#!/bin/bash

ROLE=$1

if [ "$(id -u)" != "0" ]; then
  echo "Run as root: sudo bash 02_permissions.sh web|app|db|ops"
  exit 1
fi

if [ "$ROLE" != "web" ] && [ "$ROLE" != "app" ] && [ "$ROLE" != "db" ] && [ "$ROLE" != "ops" ]; then
  echo "Usage: sudo bash 02_permissions.sh web|app|db|ops"
  exit 1
fi

echo "== File permissions =="

chown root:nc-ttp /etc/nc-ttp
chmod 750 /etc/nc-ttp
echo "  /etc/nc-ttp          root:nc-ttp 750"

chown root:nc-ttp-deploy /opt/nc-ttp
chmod 775 /opt/nc-ttp
echo "  /opt/nc-ttp          root:nc-ttp-deploy 775"

if [ -d /opt/nc-ttp/app ]; then
  chown root:nc-ttp-deploy /opt/nc-ttp/app
  chmod 775 /opt/nc-ttp/app
  echo "  /opt/nc-ttp/app      root:nc-ttp-deploy 775"
fi

if [ -d /opt/nc-ttp/releases ]; then
  chown root:nc-ttp-deploy /opt/nc-ttp/releases
  chmod 775 /opt/nc-ttp/releases
  echo "  /opt/nc-ttp/releases root:nc-ttp-deploy 775"
fi

chown nc-ttp:nc-ttp-audit /var/log/nc-ttp
chmod 750 /var/log/nc-ttp
echo "  /var/log/nc-ttp      nc-ttp:nc-ttp-audit 750"

chown root:root /var/backups/nc-ttp
chmod 700 /var/backups/nc-ttp
echo "  /var/backups/nc-ttp  root:root 700"

echo "== Sudo rules =="

cat > /etc/sudoers.d/nc-ttp-admin <<'EOF'
%nc-ttp-admin ALL=(ALL) ALL
EOF
chmod 440 /etc/sudoers.d/nc-ttp-admin
echo "  /etc/sudoers.d/nc-ttp-admin"

cat > /etc/sudoers.d/nc-ttp-deploy <<'EOF'
%nc-ttp-deploy ALL=(root) /usr/bin/systemctl start nc-ttp, /usr/bin/systemctl stop nc-ttp, /usr/bin/systemctl restart nc-ttp, /usr/bin/systemctl status nc-ttp
EOF
chmod 440 /etc/sudoers.d/nc-ttp-deploy
echo "  /etc/sudoers.d/nc-ttp-deploy"

cat > /etc/sudoers.d/nc-ttp-bot <<'EOF'
automation_bot ALL=(root) NOPASSWD: /usr/bin/systemctl restart nc-ttp, /usr/bin/systemctl status nc-ttp
EOF
chmod 440 /etc/sudoers.d/nc-ttp-bot
echo "  /etc/sudoers.d/nc-ttp-bot"

cat > /etc/sudoers.d/nc-ttp-audit <<'EOF'
%nc-ttp-audit ALL=(root) NOPASSWD: /usr/bin/journalctl -u nc-ttp
EOF
chmod 440 /etc/sudoers.d/nc-ttp-audit
echo "  /etc/sudoers.d/nc-ttp-audit"

echo "== Check sudoers syntax =="
visudo -c

echo
echo "== Result on $(hostname) =="
ls -ld /etc/nc-ttp /opt/nc-ttp /var/log/nc-ttp /var/backups/nc-ttp
ls -l /etc/sudoers.d
echo "Permissions for role $ROLE are ready"
