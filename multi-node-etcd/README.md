# Multi master installation

https://blog.inkubate.io/install-and-configure-a-multi-master-kubernetes-cluster-with-kubeadm/

## Vagrant up

```
vagrant up
```

## Haproxy

Check Haproxy: 

```sh
nc -v 192.168.2.200 6443
```

### Generate certificates

```sh

cat > ca-config.json <<EOF
{
  "signing": {
    "default": {
      "expiry": "8760h"
    },
    "profiles": {
      "kubernetes": {
        "usages": ["signing", "key encipherment", "server auth", "client auth"],
        "expiry": "8760h"
      }
    }
  }
}
EOF

cat > ca-csr.json <<EOF
{
  "CN": "Kubernetes",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
  {
    "C": "NL",
    "L": "Rotterdam",
    "O": "Kubernetes",
    "OU": "CA",
    "ST": "ZH"
  }
 ]
}
EOF
```

```sh
cfssl gencert -initca ca-csr.json | cfssljson -bare ca

cfssl gencert \
-ca=ca.pem \
-ca-key=ca-key.pem \
-config=ca-config.json \
-hostname=192.168.2.200,192.168.2.201,192.168.2.202,127.0.0.1,kubernetes.default \
-profile=kubernetes ca-csr.json | \
cfssljson -bare kubernetes

(
scp ca.pem kubernetes.pem kubernetes-key.pem vagrant@192.168.2.201:~
scp ca.pem kubernetes.pem kubernetes-key.pem vagrant@192.168.2.202:~
)
```

### Install etcd

```sh
(
sudo mkdir /etc/etcd /var/lib/etcd
sudo cp ~/ca.pem ~/kubernetes.pem ~/kubernetes-key.pem /etc/etcd
)
```


```sh
sudo vim /etc/systemd/system/etcd.service

[Unit]
Description=etcd
Documentation=https://github.com/coreos


[Service]
ExecStart=/usr/local/bin/etcd \
  --name 192.168.2.202 \
  --cert-file=/etc/etcd/kubernetes.pem \
  --key-file=/etc/etcd/kubernetes-key.pem \
  --peer-cert-file=/etc/etcd/kubernetes.pem \
  --peer-key-file=/etc/etcd/kubernetes-key.pem \
  --trusted-ca-file=/etc/etcd/ca.pem \
  --peer-trusted-ca-file=/etc/etcd/ca.pem \
  --peer-client-cert-auth \
  --client-cert-auth \
  --initial-advertise-peer-urls https://192.168.2.202:2380 \
  --listen-peer-urls https://192.168.2.202:2380 \
  --listen-client-urls https://192.168.2.202:2379,http://127.0.0.1:2379 \
  --advertise-client-urls https://192.168.2.202:2379 \
  --initial-cluster-token etcd-cluster-0 \
  --initial-cluster 192.168.2.200=https://192.168.2.200:2380,192.168.2.201=https://192.168.2.201:2380,192.168.2.202=https://192.168.2.202:2380 \
  --initial-cluster-state new \
  --data-dir=/var/lib/etcd
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
```

```sh
(
sudo systemctl daemon-reload
sudo systemctl enable etcd
sudo systemctl stop etcd
sudo systemctl start etcd
sudo systemctl status etcd
sudo journalctl -u etcd
)

# Test
etcdctl member list

```

 
## Master/worker nodes

Optional: remove the NAT interface in Virtualbox  
Optional: remove known_hosts entries  

```sh
ssh-keygen -f "$HOME/.ssh/known_hosts" -R "192.168.2.201"
ssh-keygen -f "$HOME/.ssh/known_hosts" -R "192.168.2.202"
```

### Install etcd 

See previous section
 
### Kubeadm

Create config.yaml

```
apiVersion: kubeadm.k8s.io/v1beta2
kind: InitConfiguration
localAPIEndpoint:
  advertiseAddress: 192.168.2.201
  bindPort: 6443
---
apiVersion: kubeadm.k8s.io/v1beta2
kind: ClusterConfiguration
kubernetesVersion: stable
clusterName: kubelab
networking:
      podSubnet: "10.244.0.0/16" 
controlPlaneEndpoint: "192.168.2.200:6443" 
etcd:
  external:
    endpoints:
    - https://192.168.2.200:2379
    - https://192.168.2.201:2379
    - https://192.168.2.202:2379
    caFile: /etc/etcd/ca.pem
    certFile: /etc/etcd/kubernetes.pem
    keyFile: /etc/etcd/kubernetes-key.pem
   
    
```
execute init

```
sudo kubeadm init --config config.yaml  --upload-certs

(
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

source <(kubectl completion bash) 
echo "source <(kubectl completion bash)" >> ~/.bashrc
)

kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
```

Wait until all is up and running and add add second node.

```sh
sudo kubeadm join 192.168.2.200:6443 --token sb2jdixxxx \
    --discovery-token-ca-cert-hash sha256:3e13f47b8e67953bxxxxx \
    --control-plane --certificate-key 82005ccf87f3aa1b06903d76b4647exxxxx
```

Add worker roles to masters  

```sh
kubectl taint nodes --all node-role.kubernetes.io/master-
```

## Install dashboard

```sh
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-beta4/aio/deploy/recommended.yaml
cat > dashboard.yaml <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard
EOF

kubectl -n kubernetes-dashboard describe secret $(kubectl -n kubernetes-dashboard get secret | grep admin-user | awk '{print $1}')
```

## Metallb

```sh
kubectl apply -f https://raw.githubusercontent.com/google/metallb/v0.8.3/manifests/metallb.yaml

cat > metal.yaml << EOF
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: metallb-system
  name: config
data:
  config: |
    address-pools:
    - name: default
      protocol: layer2
      addresses:
      - 192.168.1.203-192.168.1.210
EOF

cat > dashboard-service.yaml << EOF
apiVersion: v1
kind: Service
metadata:
  labels:
    app.kubernetes.io/name: load-balancer-dashboard
  name: dashboard-service
  namespace: kubernetes-dashboard
spec:
  ports:
    - port: 8080
      protocol: TCP
      targetPort: 8443
  selector:
    k8s-app: kubernetes-dashboard
  type: LoadBalancer
EOF
```

http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/#/login

## Ingress

```sh
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/mandatory.yaml

kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/provider/cloud-generic.yaml
```

# Test

```sh
kubectl apply -f https://github.com/jacqinthebox/vagrant-kubernetes/blob/master/microbot.yaml
kubectl get pod -o=custom-columns=NAME:.metadata.name,STATUS:.status.phase,NODE:.spec.nodeName --all-namespaces
```
