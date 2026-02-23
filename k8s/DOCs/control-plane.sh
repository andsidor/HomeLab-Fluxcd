#!/usr/bin/env bash

set -e

K8S_VERSION="v1.34"
POD_CIDR="10.0.0.0/16"
CILIUM_VERSION="v0.16.24"

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
curl -fsSL https://pkgs.k8s.io/core:/stable:/${K8S_VERSION}/deb/Release.key \
  | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo \
  "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] \
  https://pkgs.k8s.io/core:/stable:/${K8S_VERSION}/deb/ /" \
  | tee /etc/apt/sources.list.d/kubernetes.list

echo "==> Install kubelet, kubeadm, kubectl"
apt-get update
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

systemctl enable --now kubelet

echo "==> Initialize Kubernetes control plane"
kubeadm init \
  --pod-network-cidr=${POD_CIDR} \
  --cri-socket=unix:///run/containerd/containerd.sock



curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash


curl -s https://fluxcd.io/install.sh | sudo bash



