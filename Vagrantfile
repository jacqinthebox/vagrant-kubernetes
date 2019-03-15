# -*- mode: ruby -*-
# vi: set ft=ruby :
$script = <<-SCRIPT
wget https://raw.githubusercontent.com/jacqinthebox/arm-templates-and-configs/optimize-kube/kubernetes-cluster/vagrant-install.sh && chmod +x vagrant-install.sh
SCRIPT

Vagrant.configure("2") do |config|
  config.vm.define "machine01" do |machine01_config|
    machine01_config.vm.box = "ubuntu/bionic64"
    machine01_config.vm.box_version = "20190308.0.0"    
    machine01_config.vm.network "public_network", bridge: "enp3s0", ip: "192.168.2.50"
    machine01_config.vm.hostname = "machine01"
    machine01_config.vm.provider "virtualbox" do |v|
      v.linked_clone = true
      v.memory = 8192 
      v.cpus = 2
    end
  end
  config.vm.provision "shell", inline: $script
end

