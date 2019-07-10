# Bootstrap a single node Kubernetes cluster with Kubeadm and Vagrant

The purpose of this box is to quickly install a K8s cluster, roll your own microservices on top of it, break it down and see how it works. Inspired by this article: https://medium.com/@lizrice/kubernetes-in-vagrant-with-kubeadm-21979ded6c63.

I prefer bootstrapping with Kubeadm instead of Minikube or Docker for Desktop because this approach better reflects a production setup and it gives you the option to add worker nodes as well. 

What is installed:  
* Ubuntu 18.04.02 LTS
* Docker
* Kubeadm
* Single node Kubernetes cluster
* Flannel
* Nginx Ingress
* Kubernetes Dashboard
* Helm

Customizations:  
* The Nginx ingress controller will also listen to 1433 (mssql). See the configmap.
* it is set to use hostnetwork is set to true to have it work on a single node bare metal cluster
* the Dashboard is set to use NodePort to be able to browse to it via its TCP port instead of using `kubectl proxy`. 

## Instructions

Install [Vagrant](https://www.vagrantup.com/) and [Virtualbox](https://www.virtualbox.org/).

Create some folders, e.g.
```sh
mkdir -p ~/vagrant/single-master
cd ~/vagrant/single-master
```

Then fetch the Vagrantfile:
```sh
wget https://raw.githubusercontent.com/jacqinthebox/vagrant-kubernetes/master/Vagrantfile
```

**Then edit the Vagrantfile and adjust the variables on top to match your IP config and cluster- and SAN names**

For example, when on Linux:  
To find your Gateway type `netstat -rn`   
To find your DNS type `nmcli dev show | grep DNS`  

In Windows `ipconfig /all` will do the trick.

Then bootstrap the cluster like so:

```sh
vagrant up node01
```

Sit back and wait for it to finish. 


## Log in to the Dashboard

Note the Dashboard url and the token in the script output. 
Copy the token and head over to the Dashboad url. Paste the token into the logon form.


## Optional: deploy example application

```
kubectl apply -f https://raw.githubusercontent.com/jacqinthebox/vagrant-kubernetes/master/microbot.yaml
```

## How does this work?

I really wanted the cluster to have a custom clustername, else they are all named `kubernetes` :)
This can only be done with a configfile for kubeadm.

This is why the [script](https://github.com/jacqinthebox/vagrant-kubernetes/blob/master/kubernetes-vagrant-install.sh) takes in 3 arguments: clustername, san1 and san2.

With these arguments, a configfile is created for the kubeadm init:

```yaml
apiVersion: kubeadm.k8s.io/v1beta1
kind: ClusterConfiguration
clusterName: $1
networking:
  podSubnet: 10.244.0.0/16
apiServer:
  CertSANs:
  - "$2"
  - "$3"
etcd:
  local:
    serverCertSANs:
      - "$2"
      - "$3"
    peerCertSANs:
      - "$2"
      - "$3"
```

Just have a further look in the [script](https://github.com/jacqinthebox/vagrant-kubernetes/blob/master/kubernetes-vagrant-install.sh) to see how I constructed the cluster. Of course I am open for suggestions.  

## Disclaimer
Do not use this in production. Vagrant boxes are meant for developing and testing.

## Resources

[https://github.com/kubernetes/kubernetes/issues/33618](https://github.com/kubernetes/kubernetes/issues/33618)  
[https://github.com/kubernetes/kubeadm/issues/1330](https://github.com/kubernetes/kubeadm/issues/1330)  
[https://godoc.org/k8s.io/kubernetes/cmd/kubeadm/app/apis/kubeadm/v1beta1](https://godoc.org/k8s.io/kubernetes/cmd/kubeadm/app/apis/kubeadm/v1beta1)  
[https://github.com/kubernetes/kubeadm/blob/master/docs/design/design_v1.9.md](https://github.com/kubernetes/kubeadm/blob/master/docs/design/design_v1.9.md)  
[https://github.com/kubernetes/kubernetes/issues/68333](https://github.com/kubernetes/kubernetes/issues/68333)  
[https://blog.scottlowe.org/2018/08/21/bootstrapping-etcd-cluster-with-tls-using-kubeadm/](https://blog.scottlowe.org/2018/08/21/bootstrapping-etcd-cluster-with-tls-using-kubeadm/)  
[https://medium.com/@lizrice/kubernetes-in-vagrant-with-kubeadm-21979ded6c63](https://medium.com/@lizrice/kubernetes-in-vagrant-with-kubeadm-21979ded6c63)  

