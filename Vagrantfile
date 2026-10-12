NODES = [
  { name: "nc-ttp-web", ip: "192.168.56.10", cpus: 1, memory: 1024, role: "web", ports: { 80 => 8080 } },
  { name: "nc-ttp-app", ip: "192.168.56.11", cpus: 2, memory: 2048, role: "app", ports: {} },
  { name: "nc-ttp-db",  ip: "192.168.56.12", cpus: 1, memory: 2048, role: "db",  ports: {} },
  { name: "nc-ttp-ops", ip: "192.168.56.13", cpus: 1, memory: 1536, role: "ops", ports: { 3000 => 3000 } },
]

Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-24.04"
  config.vm.box_check_update = false

  NODES.each do |node|
    config.vm.define node[:name] do |vm|
      vm.vm.hostname = node[:name]
      vm.vm.network "private_network", ip: node[:ip]
      node[:ports].each do |guest, host|
        vm.vm.network "forwarded_port", guest: guest, host: host
      end

      vm.vm.provider "virtualbox" do |vb|
        vb.name = node[:name]
        vb.cpus = node[:cpus]
        vb.memory = node[:memory]
        vb.linked_clone = true
      end

      vm.vm.provision "shell", path: "scripts/common.sh"
      vm.vm.provision "shell", path: "scripts/setup_fs.sh", args: [node[:role]]
      vm.vm.provision "shell", path: "scripts/01_users.sh", args: [node[:role]]
      vm.vm.provision "shell", path: "scripts/02_permissions.sh", args: [node[:role]]
      vm.vm.provision "shell", path: "scripts/03_ssh.sh"
      vm.vm.provision "shell", path: "scripts/04_service.sh", args: [node[:role]]
    end
  end
end
