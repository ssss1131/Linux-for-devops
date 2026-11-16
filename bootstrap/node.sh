#!/bin/bash

PUB=/vagrant/keys/ansible_control.pub

if [ ! -f "$PUB" ]; then
  echo "No $PUB yet. Bring up nc-ttp-ops first: vagrant up nc-ttp-ops"
  exit 1
fi

if ! grep -qF "$(cat $PUB)" /home/vagrant/.ssh/authorized_keys; then
  cat "$PUB" >> /home/vagrant/.ssh/authorized_keys
  echo "  ansible_control key added for vagrant"
else
  echo "  ansible_control key already present"
fi

echo "Node $(hostname) is ready for Ansible"
