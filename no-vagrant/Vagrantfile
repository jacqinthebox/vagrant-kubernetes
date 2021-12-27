# -*- mode: ruby -*-
# vi: set ft=ruby :

# Find your bridge interface name, e.g. with ip add or ifconfig or ipconfig
BRIDGE_IF="enp3s0"
# This will be the fixed IP address of the virtual machine
IP_ADDR_NODE01="192.168.2.211"

#Also adjust the 6 variables in the script section:
$script = <<-SCRIPT

IP_ADDR_NODE01="192.168.2.211"
GATEWAY="192.168.2.254"
DNS="192.168.2.243"
CLUSTER="kubelab"
SAN1="kubelab"
SAN2="kubelab.localdomain.local"

echo "copy install script"
wget https://raw.githubusercontent.com/peterconnects/kubernetes-scripts/master/install.sh && chmod u=rwx install.sh && chown vagrant.vagrant install.sh

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
echo "restarting ssh service"
service ssh restart
echo "sshd has been restarted"

echo "installing kubernetes"
echo "running command ./install.sh ${CLUSTER} ${IP_ADDR_NODE01} ${SAN1} ${SAN2}"
./install.sh $CLUSTER $IP_ADDR_NODE01 $SAN1 $SAN2

SCRIPT

$extra = <<-EXTRA
# fixing locations and ownership
cp /root/.kube /root/.helm /root/installation* /home/vagrant/ -a
chown vagrant.vagrant /home/vagrant/.kube -R
chown vagrant.vagrant /home/vagrant/.helm -R
chown vagrant.vagrant /home/vagrant/install*

# Install extras

apt-get install -y curl git gitk vim-nox p7zip-full build-essential linux-headers-$(uname -r) software-properties-common cmake python3-dev wget  neofetch net-tools nmap iptraf htop neofetch tcpdump
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

wget -q https://github.com/mozilla/sops/releases/download/3.4.0/sops_3.4.0_amd64.deb 
dpkg -i sops_3.4.0_amd64.deb

mkdir -p /tmp/gitrepos && cd /tmp/gitrepos
git clone https://github.com/powerline/fonts.git
cd fonts && ./install.sh
cp /root/.local /home/vagrant -a
chown vagrant.vagrant /home/vagrant/.local -R

cd

# Better vim

mkdir -p /home/vagrant/.vim/autoload /home/vagrant/.vim/bundle && curl -LSso /home/vagrant/.vim/autoload/pathogen.vim https://tpo.pe/pathogen.vim
cd /home/vagrant/.vim/bundle
git clone https://github.com/scrooloose/nerdtree.git
git clone https://github.com/Valloric/MatchTagAlways.git
git clone https://github.com/ctrlpvim/ctrlp.vim.git
git clone https://github.com/vim-airline/vim-airline.git 
git clone https://github.com/vim-airline/vim-airline-themes.git 
git clone https://github.com/lukaszb/vim-web-indent.git
git clone https://github.com/hashivim/vim-vagrant.git
git clone https://github.com/w0rp/ale.git

mkdir -p /home/vagrant/.vim/colors && cd /home/vagrant/.vim/colors
wget -q https://raw.githubusercontent.com/altercation/vim-colors-solarized/master/colors/solarized.vim


cat > /home/vagrant/.vimrc <<EOF
set laststatus=2
set number
set wrap
set linebreak
set expandtab
set shiftwidth=2
set softtabstop=2
set clipboard=unnamedplus
execute pathogen#infect()
filetype plugin indent on
syntax on
let NERDTreeShowHidden=1
map <F7> mzgg=G`z<CR>
map <F5> :NERDTreeToggle<CR>
set paste

"disable insert key replace toggle:
function s:ForbidReplace()
    if v:insertmode isnot# 'i'
        call feedkeys("\<Insert>", "n")
    endif
endfunction
augroup ForbidReplaceMode
    autocmd!
    autocmd InsertEnter  * call s:ForbidReplace()
    autocmd InsertChange * call s:ForbidReplace()
augroup END

"tabs
nnoremap <C-t> :tabnew<Space>
inoremap <C-t> <Esc>:tabnew<Space>

"Tab Navigation
nnoremap <S-h> gT
nnoremap <S-l> gt

"may change from system to system
"set t_Co=256
set background=dark
colorscheme solarized
set fillchars=""
EOF

chown vagrant.vagrant /home/vagrant/.vim -R
chown vagrant.vagrant /home/vagrant/.vimrc

echo "Extras were installed like vim, nmap, sops and az cli."
echo "All done."
EXTRA


Vagrant.configure("2") do |config|
  config.vm.define "node01" do |node01_config|
    node01_config.vm.box = "ubuntu/bionic64"
    node01_config.vm.hostname = "kube01"
    node01_config.disksize.size = '20GB'
    node01_config.vm.network "public_network", bridge: BRIDGE_IF, ip: IP_ADDR_NODE01
    node01_config.vm.provider "virtualbox" do |v|
      v.linked_clone = true
      v.memory = 8192
    end
  end
  config.vm.provision "shell", inline: $script
  config.vm.provision "shell", inline: $extra
end


