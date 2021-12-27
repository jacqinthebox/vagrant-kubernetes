# Install Kubernetes

This is how to install a Kubernetes cluster with kubeadm.

## Installation instructions

### Bootstrap the cluster

```sh
IP=your-ip-address

wget -O install.sh https://raw.githubusercontent.com/peterconnects/kubernetes-scripts/master/install.sh 
chmod u=rwx install.sh

sudo ./install.sh kubelab $IP  2>&1 | tee outfile
```

### Reset

```sh
sudo kubeadm reset --force && \
  sudo rm -rf kubeadm-config.yaml helm* install.sh && \
  sudo rm -rf /tmp/installed
sudo rm -rf ~/.kube && sudo rm -rf ~/.helm
```

### Increase disksize for the Vagrantbox

Thanks to this plugin: https://github.com/sprotheroe/vagrant-disksize.

```sh
vagrant plugin install vagrant-disksize
```
Example: 

```
Vagrant.configure('2') do |config|
  config.vm.box = 'ubuntu/xenial64'
  config.disksize.size = '50GB'
end
```
### Network instructions for the Vagrant box(es)

Edit the Vagrantfile. Adjust the variables on top to match your IP config and cluster- and SAN names**:

* to find a free IP address in your subnet, type e.g. `nmap -sP 192.168.1.0/24` 
* to find your bridge interface, type `net add` 
* to find your Gateway type `netstat -rn` or `ip r`
* to find your DNS type `nmcli dev show | grep DNS`

In Windows `ipconfig /all` will do the trick.

Then bootstrap the cluster like so:

```
vagrant up
```

## What is installed

### Kubernetes cluster 

Kubernetes is installed with the following customizations:

* The ingress controller will also listen to 1433 (mssql). See the configmap.
* The ingress controller is set to use hostnetwork = true to have it work on a single node bare metal cluster
* The dashboard is set to use NodePort to be able to browse to it via its TCP port instead of using kubectl proxy.

### Software and tools

The following packages are installed on top of Ubuntu 18.04.03 LTS:

* Build tools
* Misc tools like vim, wget, curl, git, tcpdump, nmap
* Docker
* Kubeadm
* Kubelet
* Flannel
* Nginx Ingress controller
* Kubernetes Dashboard
* Helm
* Azure CLI
* Mozilla SOPS


### Ingress & SQL Server on a single node cluster without a load balancer

What if we want to expose MSSQL over port 1433?

We need to set the hostNetwork to true, as documented here:  
https://kubernetes.github.io/ingress-nginx/deploy/baremetal/#via-the-host-network

We need to expose the extra TCP port like so:  
https://kubernetes.github.io/ingress-nginx/user-guide/exposing-tcp-udp-services

The tcp service configmap looks like so:

```yaml
kind: ConfigMap
apiVersion: v1
metadata:
  name: tcp-services
  namespace: ingress-nginx
  labels:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx
data:
  1433: "default/mssql-service:1433"
```

When deploying mssql, we need to expose mssql via a service like so:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: mssql-service
  labels:
    release: {{ .Release.Name }}-mssql
spec:
  selector:
    app: mssql
  ports:
    - protocol: TCP
      port: 1433
      targetPort: 1433
  type: NodePort

```
