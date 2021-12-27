#! /bin/sh

if [ ! -f /tmp/installed ]; then

if [ -z "$1" ]
then
	echo "You forgot the clustername. You should run the script with a variable like so: sudo ./install.sh clustername ip-adress"
	echo "Exiting"
	exit 2
fi

echo "[prepare] Creating the config file for kubeadm with clustername $1"

if [ -f kubeadm-config.yaml  ]; then
    echo "There is already a kubeadm-config.yaml. Please delete it first"
    exit 2
fi

cat > kubeadm-config.yaml <<EOF
apiVersion: kubeadm.k8s.io/v1beta2
kind: InitConfiguration
localAPIEndpoint:
  advertiseAddress: $2
  bindPort: 6443
---
apiVersion: kubeadm.k8s.io/v1beta2
kind: ClusterConfiguration
clusterName: $1
kubernetesVersion: "v1.15.4"
networking:
  podSubnet: 10.244.0.0/16
apiServer:
  CertSANs:
  - "$1"
  - "$2"
etcd:
  local:
    serverCertSANs:
      - "$1"
      - "$2"
    peerCertSANs:
      - "$1"
      - "$2"
controllerManager:
  extraArgs:
    "address": "0.0.0.0"
scheduler:
  extraArgs:
    "address": "0.0.0.0"
EOF

echo "[prepare] Turning off swap"
swapoff -a
cp /etc/fstab ~/fstab.old
sed -i '/swapfile/d' /etc/fstab

echo "[prepare] Installing Docker!"
apt-get update && apt-get install -y apt-transport-https ca-certificates software-properties-common docker.io openssh-server jq
systemctl start docker &&  systemctl enable docker
usermod -aG docker $USER

echo "[kube-install] Installing Kubernetes"
apt-get update && apt-get install -y apt-transport-https curl
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -

rm -rf /etc/apt/sources.list.d/kubernetes.list
rm -rf /etc/apt/sources.list.d/kubernetes.list.save

cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF

apt-get update
#apt-get install -y kubelet  kubeadm kubectl
echo "[kube-install] Installing kubeadm, kubectl and kubelet version 1.15.4"
apt-get install -y kubectl=1.15.4-00 kubeadm=1.15.4-00 kubelet=1.15.4-00

echo "[kube-install] Running kubeadm"
kubeadm init --config=kubeadm-config.yaml #--pod-network-cidr=10.244.0.0/16
export KUBECONFIG=/etc/kubernetes/admin.conf

echo "[postdeployment] Installing Flannel"
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
touch /tmp/installed

echo "[postdeployment] Taint the master so it can host pods"
kubectl taint nodes --all node-role.kubernetes.io/master-

echo "[postdeployment] Install Dashboard"
kubectl create serviceaccount cluster-admin-dashboard-sa
kubectl create clusterrolebinding cluster-admin-dashboard-sa --clusterrole=cluster-admin --serviceaccount=default:cluster-admin-dashboard-sa
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v1.10.1/src/deploy/recommended/kubernetes-dashboard.yaml

echo "[postdeployment] Install Helm, wait for the Tiller pod to get ready"

#curl https://raw.githubusercontent.com/helm/helm/master/scripts/get | bash
wget https://get.helm.sh/helm-v2.14.3-linux-amd64.tar.gz
tar -xvf helm-v2.14.3-linux-amd64.tar.gz
cd linux-amd64
mv helm /usr/local/bin && mv tiller /usr/local/bin
kubectl create clusterrolebinding permissive-binding --clusterrole=cluster-admin --user=admin --user=kubelet --group=system:serviceaccounts
helm init --service-account default

ATTEMPTS=0
ROLLOUT_STATUS_CMD="kubectl rollout status deployment/tiller-deploy -n kube-system"
until $ROLLOUT_STATUS_CMD || [ $ATTEMPTS -eq 60 ]; do
  $ROLLOUT_STATUS_CMD
  ATTEMPTS=$((attempts + 1))
  sleep 10
done

echo "[postdeployment] Install a customized ingress"
kubectl apply -f https://raw.githubusercontent.com/peterconnects/kubernetes-scripts/master/ingress-mandatory.yaml
#kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/provider/baremetal/service-nodeport.yaml

#This belongs to the SQL Server deployment.
#echo "[postdeployment] Expose port 1433 for Sql"
#kubectl apply -f https://raw.githubusercontent.com/peterconnects/kubernetes-scripts/master/mssql-configmap.yaml

#echo "[postdeployment] Install Ingress with Helm"
#helm install stable/nginx-ingress --name v1 --namespace kube-system --set controller.hostNetwork=true --set rbac.create=true --set controller.kind=Deployment --set controller.extraArgs.v=2 --set controller.extraArgs.tcp-services-configmap=default/sql-services

echo "[postdeployment] Set the Kubernetes Dashboard to NodePort"
kubectl -n kube-system get service/kubernetes-dashboard -o yaml | sed "s/type: ClusterIP/type: NodePort/" | kubectl replace -f -

echo "[postdeployment] Creating shared folders to mount into the pods"
mkdir -p /var/peterconnects/db

else
        echo "It looks like you installed already ran this script."
fi

echo "[end] Done. Now fetching the token for the dashboard:"
echo ""

KEY=`kubectl get secret $(kubectl get serviceaccount cluster-admin-dashboard-sa -o jsonpath="{.secrets[0].name}") -o jsonpath="{.data.token}" | base64 --decode`
echo $KEY

echo ""
echo ""
echo "You can also get the key manually like this:"
echo "  kubectl get secret | grep cluster-admin-dashboard-sa"
echo "  kubectl describe secret <secretname>"
echo ""
echo "Your dashboard url is:"

DASHBOARDPORT=`kubectl get services --all-namespaces | grep kubernetes-dashboard | awk '{print $6}' | cut -f 2 -d ':' | cut -f 1 -d '/'`
#IPADDR=`ifconfig enp0s8 | grep mask | awk '{print $2}'`

echo ""
echo " https://$2:$DASHBOARDPORT"
echo ""
echo "[end] If you want to reinitialize the cluster, run"
echo ""
echo " sudo kubeadm reset --force && sudo rm -rf kubeadm-config.yaml helm* install.sh && sudo rm -rf /tmp/installed"
echo " sudo rm -rf ~/.kube && sudo rm -rf ~/.helm"
echo ""
echo "[end] To install autocomplete for kubectl, copy and paste the following in your shell:"
echo ""
echo "  source <(kubectl completion bash)" 
echo "  echo "\""source <(kubectl completion bash)"\"" >> ~/.bashrc"
echo ""
echo "[end] Generating installation report in installation-report.txt"

cd
now=$(date +"%Y_%m_%d_%I_%M")

cat > installation-report-$now.txt <<EOF

+++ INSTALLATION REPORT +++

Kubernetes advertiseAddress: $2
clusterName: $1
kubernetesVersion: "v1.15.4"
podSubnet: 10.244.0.0/16

Dashboard Url: https://$2:$DASHBOARDPORT
Dashboard Key: $KEY

If you want to reinitialize the cluster, run
sudo kubeadm reset --force && sudo rm -rf kubeadm-config.yaml helm* install.sh && sudo rm -rf /tmp/installed
sudo rm -rf ~/.kube && sudo rm -rf ~/.helm

To install autocomplete for kubectl, copy and paste the following in your shell:
source <(kubectl completion bash) 
echo "source <(kubectl completion bash)" >> ~/.bashrc

+++ END OF INSTALLATION REPORT +++
EOF

# disabling updating Kubernetes
# disabling updating Kubernetes
if [ -f /etc/apt/sources.list.d/kubernetes.list ]; then
  sed -i -e 's/^/#/g' /etc/apt/sources.list.d/kubernetes.list
fi
if [ -f /etc/apt/sources.list.d/kubernetes.list.save ]; then
  sed -i -e 's/^/#/g' /etc/apt/sources.list.d/kubernetes.list.save
fi


chmod 766 installation-report-$now.txt
#This is last because value of variable is reset

#ME=`who | awk '{print $1}'`
ME=${SUDO_USER:-$(whoami)}
usermod -aG docker $ME
echo "[postdeployment] Arranging access to the cluster for ${ME} and settiung correct permissions on Helm folders.\n"
mkdir -p /home/${ME}/.kube
cp /etc/kubernetes/admin.conf /home/${ME}/.kube/config
chown ${ME}:${ME} /home/${ME}/.kube -R
sudo chown ${ME}:${ME} /home/${ME}/.helm -R

echo "[end] The script is completed."
echo "[end] This is the installation report: "
less installation-report-$now.txt
