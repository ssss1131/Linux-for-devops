#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

echo "== Install Ansible on the control node =="
apt-get update -q
apt-get install -yq ansible python3-passlib

echo "== SSH key for Ansible =="
mkdir -p /vagrant/keys
if [ ! -f /vagrant/keys/ansible_control ]; then
  ssh-keygen -t ed25519 -N "" -C ansible_control -f /vagrant/keys/ansible_control
  echo "  key pair created in /vagrant/keys"
else
  echo "  key pair already exists in /vagrant/keys"
fi

cp /vagrant/keys/ansible_control /home/vagrant/.ssh/id_ed25519
cp /vagrant/keys/ansible_control.pub /home/vagrant/.ssh/id_ed25519.pub
chown vagrant:vagrant /home/vagrant/.ssh/id_ed25519 /home/vagrant/.ssh/id_ed25519.pub
chmod 600 /home/vagrant/.ssh/id_ed25519
chmod 644 /home/vagrant/.ssh/id_ed25519.pub

echo "== Ansible config path =="
if ! grep -q ANSIBLE_CONFIG /home/vagrant/.bashrc; then
  echo 'export ANSIBLE_CONFIG=/vagrant/ansible/ansible.cfg' >> /home/vagrant/.bashrc
fi

ansible --version | head -n 1
echo "Control node is ready"
