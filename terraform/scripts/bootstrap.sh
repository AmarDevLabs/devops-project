#!/bin/bash
set -euxo pipefail

# Update system
yum update -y

# Install Docker
amazon-linux-extras install docker -y
systemctl enable docker
systemctl start docker
usermod -aG docker ec2-user

# Disable swap
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab

# Kernel modules and sysctl for Kubernetes
cat >/etc/modules-load.d/k8s.conf <<'EOF'
br_netfilter
EOF

modprobe br_netfilter

cat >/etc/sysctl.d/k8s.conf <<'EOF'
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF

sysctl --system

# Kubernetes repo
cat >/etc/yum.repos.d/kubernetes.repo <<'EOF'
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.29/rpm/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.29/rpm/repodata/repomd.xml.key
EOF

# Install kubelet, kubeadm, kubectl
yum install -y kubelet kubeadm kubectl
systemctl enable kubelet

# Helpful tools
yum install -y git curl wget vim

echo "Bootstrap complete" >/var/log/bootstrap-complete.log
