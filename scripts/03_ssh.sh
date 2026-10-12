#!/bin/bash

if [ "$(id -u)" != "0" ]; then
  echo "Run as root: sudo bash 03_ssh.sh"
  exit 1
fi

KEYDIR=/vagrant/keys
KEY=$KEYDIR/automation_bot

echo "== SSH key pair =="

mkdir -p $KEYDIR

if [ ! -f $KEY ]; then
  ssh-keygen -t ed25519 -N "" -C automation_bot -f $KEY
  echo "  key pair created in $KEYDIR"
else
  echo "  key pair already exists in $KEYDIR"
fi

echo "== Authorized key for automation_bot =="

mkdir -p /home/automation_bot/.ssh
cp $KEY.pub /home/automation_bot/.ssh/authorized_keys
chown -R automation_bot:automation_bot /home/automation_bot/.ssh
chmod 700 /home/automation_bot/.ssh
chmod 600 /home/automation_bot/.ssh/authorized_keys
echo "  /home/automation_bot/.ssh/authorized_keys installed"

mkdir -p /root/.ssh
cp $KEY /root/.ssh/automation_bot
chmod 700 /root/.ssh
chmod 600 /root/.ssh/automation_bot
echo "  private key copied to /root/.ssh/automation_bot"

echo "== SSH server settings =="

cat > /etc/ssh/sshd_config.d/99-nc-ttp.conf <<'EOF'
PubkeyAuthentication yes
PasswordAuthentication no
PermitRootLogin no
EOF
chmod 644 /etc/ssh/sshd_config.d/99-nc-ttp.conf
echo "  /etc/ssh/sshd_config.d/99-nc-ttp.conf written"

if [ -x /usr/bin/systemctl ]; then
  systemctl restart ssh
  echo "  ssh service restarted"
fi

echo
echo "== Result on $(hostname) =="
ls -l /home/automation_bot/.ssh
cat /etc/ssh/sshd_config.d/99-nc-ttp.conf
echo "SSH for automation_bot is ready"
