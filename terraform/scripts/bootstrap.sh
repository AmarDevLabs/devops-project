#!/bin/bash
set -euxo pipefail

echo "=== Bootstrap started ==="

########################################
# System update
########################################

dnf update -y

########################################
# Install required tools
########################################

dnf install -y \
  containerd \
  git \
  curl \
  wget \
  tar

########################################
# Configure containerd
########################################

mkdir -p /etc/containerd

containerd config default > /etc/containerd/config.toml

# Enable systemd cgroup driver
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' \
/etc/containerd/config.toml

systemctl enable containerd
systemctl restart containerd

########################################
# Kernel modules
########################################

cat <<EOF | tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

########################################
# Sysctl config
########################################

cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sysctl --system

########################################
# Disable swap
########################################

swapoff -a

sed -i '/swap/d' /etc/fstab

########################################
# Kubernetes repo
########################################

cat <<EOF | tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.29/rpm/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.29/rpm/repodata/repomd.xml.key
EOF

########################################
# Install Kubernetes tools
########################################

dnf install -y \
  kubelet \
  kubeadm \
  kubectl

systemctl enable kubelet

########################################
# Done
########################################

echo "=== Bootstrap completed ==="
