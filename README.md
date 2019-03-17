# Bootstrap a single node Kubernetes cluster with Kubeadm and Vagrant

## Instructions

Install [Vagrant](https://www.vagrantup.com/) and [Virtualbox](https://www.virtualbox.org/).

```shell
mkdir -p ~\vagrant\single-master
cd ~\vagrant\single-master
wget https://raw.githubusercontent.com/jacqinthebox/vagrant-kubernetes/master/Vagrantfile
vagrant up node01
```

Sit back and wait for it to finish. Once done, you will have a running Kubernetes cluster with the Kubernetes Dashboard, Nginx Ingress and Helm pre-installed.

The Nginx Ingress controller is slightly customized:
* it will also listen to 1433 (mssql). See the configmap.
* use hostnetwork is set to true to have it work on a single node bare metal cluster

## Log in to the Dashboard

Note the Dashboard url and the token in the script output. 
Copy the token and head over to the Dashboad url. Paste the token into the logon form.


## Optional: deploy example application

```
kubectl apply -f https://raw.githubusercontent.com/jacqinthebox/vagrant-kubernetes/master/microbot.yaml
```

## How does this work?

Just have a look in the kubernetes-vagrant-install.sh script :)

## Resources

[https://github.com/kubernetes/kubernetes/issues/33618](https://github.com/kubernetes/kubernetes/issues/33618)  
[https://github.com/kubernetes/kubeadm/issues/1330](https://github.com/kubernetes/kubeadm/issues/1330)  
[https://godoc.org/k8s.io/kubernetes/cmd/kubeadm/app/apis/kubeadm/v1beta1](https://godoc.org/k8s.io/kubernetes/cmd/kubeadm/app/apis/kubeadm/v1beta1)  
[https://github.com/kubernetes/kubeadm/blob/master/docs/design/design_v1.9.md](https://github.com/kubernetes/kubeadm/blob/master/docs/design/design_v1.9.md)  
[https://github.com/kubernetes/kubernetes/issues/68333](https://github.com/kubernetes/kubernetes/issues/68333)  
[https://blog.scottlowe.org/2018/08/21/bootstrapping-etcd-cluster-with-tls-using-kubeadm/](https://blog.scottlowe.org/2018/08/21/bootstrapping-etcd-cluster-with-tls-using-kubeadm/)  
[https://medium.com/@lizrice/kubernetes-in-vagrant-with-kubeadm-21979ded6c63](https://medium.com/@lizrice/kubernetes-in-vagrant-with-kubeadm-21979ded6c63)  

