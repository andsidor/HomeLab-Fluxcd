!/usr/bin/env bash

set -e

# ====== EDIT THESE VALUES ======
CONTROL_PLANE_IP="192.168.0.110"
#update when install
TOKEN="o49i2k.xxxxxxxxxxxxxxxxxx"
CA_CERT_HASH="sha256:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx..................."
# ==============================

echo "==> Disable swap"
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab

echo "==> Load kernel modules"
cat <<EOF | tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

echo "==> Set sysctl params"
cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sysctl --system

echo "==> Install dependencies"
apt-get update
apt-get install -y ca-certificates curl gpg apt-transport-https

echo "==> Install containerd"
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg \
  | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
  | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update
apt-get install -y containerd.io

echo "==> Configure containerd (systemd cgroup)"
mkdir -p /etc/containerd
containerd config default | tee /etc/containerd/config.toml > /dev/null
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

systemctl restart containerd
systemctl enable containerd

echo "==> Add Kubernetes repository"
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.34/deb/Release.key \
  | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo \
  "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] \
  https://pkgs.k8s.io/core:/stable:/v1.34/deb/ /" \
  | tee /etc/apt/sources.list.d/kubernetes.list

echo "==> Install kubelet and kubeadm"
apt-get update
apt-get install -y kubelet kubeadm
apt-mark hold kubelet kubeadm

systemctl enable --now kubelet

echo "==> Join Kubernetes cluster"
kubeadm join ${CONTROL_PLANE_IP}:6443 \
  --token ${TOKEN} \
  --discovery-token-ca-cert-hash ${CA_CERT_HASH} \
  --cri-socket unix:///run/containerd/containerd.sock

echo "======================================"
echo " Worker node successfully joined ✔"
echo "======================================"

