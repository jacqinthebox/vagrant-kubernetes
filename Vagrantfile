# -*- mode: ruby -*-
# vi: set ft=ruby :
$script = <<-SCRIPT
echo adding entries in hostfile...
if [ ! -f /tmp/foo.txt ]; then
    echo "Entries not there yet!"
    echo "192.168.2.51    node01" >> /etc/hosts
    echo "192.168.2.52    node02" >> /etc/hosts
    echo "192.168.2.53    master01" >> /etc/hosts
    echo "192.168.2.54    master02" >> /etc/hosts
    echo "192.168.2.50    nlb01" >> /etc/hosts
    touch /tmp/foo.txt
fi

echo changing sshd_config
if [ ! -f /tmp/sshd.txt ]; then
    echo "Change not there yet!"
    sed -i -e 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
    service sshd restart
    service ssh restart
    touch /tmp/sshd.txt
fi
SCRIPT

Vagrant.configure("2") do |config|
  config.vm.define "node01" do |node01_config|
    node01_config.vm.box = "ubuntu/bionic64"
    node01_config.vm.hostname = "node01"
    node01_config.vm.network "public_network", bridge: "wlp4s0", ip: "192.168.2.51"
    #node01_config.vm.network "private_network",ip: "192.168.200.51"  
    node01_config.vm.provider "virtualbox" do |v|
      v.linked_clone = true
      v.memory = 2048	
    end
  end

  config.vm.define "node02" do |node02_config|
      node02_config.vm.box = "ubuntu/bionic64"
      node02_config.vm.network "public_network", bridge: "wlp4s0", ip: "192.168.2.52" 
      #node02_config.vm.network "private_network", ip: "192.168.200.52"  
      node02_config.vm.hostname = "node02"
      node02_config.vm.provider "virtualbox" do |v|
        v.linked_clone = true
        v.memory = 2048	
    end
  end

  config.vm.define "master01" do |master01_config|
    master01_config.vm.box = "ubuntu/bionic64"
    master01_config.vm.network "public_network", bridge: "wlp4s0",ip: "192.168.2.53" 
    #master01_config.vm.network "private_network", ip: "192.168.200.53"  
    master01_config.vm.hostname = "master01"
    master01_config.vm.provider "virtualbox" do |v|
      v.linked_clone = true
      v.memory = 2048
    end
  end

  config.vm.define "master02" do |master02_config|
    master02_config.vm.box = "ubuntu/bionic64"
    master02_config.vm.network "public_network", bridge: "wlp4s0", ip: "192.168.2.54" 
    #master02_config.vm.network "private_network", ip: "192.168.200.54"  
    master02_config.vm.hostname = "master02"
    master02_config.vm.provider "virtualbox" do |v|
      v.linked_clone = true
      v.memory = 2048
    end
  end
 
  config.vm.define "nlb01" do |nlb01_config|
    nlb01_config.vm.box = "ubuntu/bionic64"
    nlb01_config.vm.network "public_network", bridge: "wlp4s0", ip: "192.168.2.50" 
    #nlb01_config.vm.network "private_network", ip: "192.168.200.50" 
    nlb01_config.vm.hostname = "nlb01"
    nlb01_config.vm.provider "virtualbox" do |v|
      v.linked_clone = true
      v.memory = 2048
    end
  end
  
config.vm.provision "shell", inline: $script
config.vm.network "public_network", bridge: "wlp4s0"
 
end

