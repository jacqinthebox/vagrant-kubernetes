# -*- mode: ruby -*-
# vi: set ft=ruby :

BRIDGE_IF="wlp4s0"
IP_ADDR_NODE01="192.168.2.51"
IP_ADDR_NODE02="192.168.2.52"

$script = <<-SCRIPT

GATEWAY="192.168.2.254"
DNS="192.168.2.254"
CLUSTER="microbot-k8s"
SAN1="microbot"
SAN2="microbot.moonstreet.local"

echo "copy install script"
wget https://raw.githubusercontent.com/jacqinthebox/vagrant-kubernetes/master/vagrant-kubernetes-install.sh && chmod u=rwx vagrant-kubernetes-install.sh && chown vagrant.vagrant vagrant-kubernetes-install.sh

if [ ! -f /tmp/50-vagrant.yaml ]; then
  echo "adding gateway"
  cp /etc/netplan/50-vagrant.yaml /tmp/
cat << EOF >> /etc/netplan/50-vagrant.yaml
      gateway4: $GATEWAY
      nameservers:
        addresses: [$DNS,9.9.9.9]
EOF

netplan --debug generate
netplan --debug apply

fi

echo "configuring SSH to allow passwords"
sed -i -e 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config

./vagrant-kubernetes-install.sh $CLUSTER $SAN1 $SAN2 

SCRIPT


Vagrant.configure("2") do |config|
  config.vm.define "node01" do |node01_config|
    node01_config.vm.box = "ubuntu/bionic64"
    node01_config.vm.hostname = "node01"
    node01_config.vm.network "public_network", bridge: BRIDGE_IF, ip: IP_ADDR_NODE01
    node01_config.vm.provider "virtualbox" do |v|
      v.linked_clone = true
      v.memory = 8192
    end
  end
  
  config.vm.define "node02" do |node02_config|
    node02_config.vm.box = "ubuntu/bionic64"
    node02_config.vm.hostname = "node02"
    node02_config.vm.network "public_network", bridge: BRIDGE_IF, ip: IP_ADDR_NODE02
    node02_config.vm.provider "virtualbox" do |v|
      v.linked_clone = true
      v.memory = 8192
    end
  end
  config.vm.provision "shell", inline: $script
end

