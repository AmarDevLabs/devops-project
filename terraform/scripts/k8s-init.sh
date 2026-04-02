#!/bin/bash
set -euo pipefail

LOG_FILE="/var/log/k8s-init.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "==== Kubernetes init started at $(date) ===="

TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" -s)

PRIVATE_IP=$(curl -s \
  -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/local-ipv4)

echo "Private IP detected: ${PRIVATE_IP}"

echo "Ensuring required services are enabled and running"
sudo systemctl enable containerd
sudo systemctl restart containerd

sudo systemctl enable kubelet
sudo systemctl restart kubelet

echo "Loading kernel modules"
sudo modprobe overlay || true
sudo modprobe br_netfilter || true

echo "Applying Kubernetes sysctl settings"
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

sudo sysctl --system

echo "Ensuring swap is disabled"
sudo swapoff -a || true

if [ -f /etc/kubernetes/admin.conf ]; then
  echo "Kubernetes already initialized. Skipping kubeadm init."
else
  echo "Running kubeadm init"
  sudo kubeadm init \
    --apiserver-advertise-address="${PRIVATE_IP}" \
    --pod-network-cidr=192.168.0.0/16
fi

echo "Configuring kubeconfig for ec2-user"
sudo mkdir -p /home/ec2-user/.kube
sudo cp -f /etc/kubernetes/admin.conf /home/ec2-user/.kube/config
sudo chown -R ec2-user:ec2-user /home/ec2-user/.kube
sudo chmod 600 /home/ec2-user/.kube/config

export KUBECONFIG=/etc/kubernetes/admin.conf

echo "Waiting for API server to respond"
for i in {1..30}; do
  if kubectl get nodes >/dev/null 2>&1; then
    echo "API server is reachable"
    break
  fi
  echo "Waiting for API server... attempt $i"
  sleep 10
done

echo "Installing Calico if not already installed"
if ! kubectl get daemonset calico-node -n kube-system >/dev/null 2>&1; then
  kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.30.3/manifests/calico.yaml
else
  echo "Calico already installed"
fi

echo "Removing control-plane taint so single node can run workloads"
kubectl taint nodes --all node-role.kubernetes.io/control-plane- || true

echo "Waiting for node to become Ready"
for i in {1..36}; do
  NODE_STATUS=$(kubectl get nodes --no-headers 2>/dev/null | awk '{print $2}' || true)
  if echo "$NODE_STATUS" | grep -q "Ready"; then
    echo "Node is Ready"
    break
  fi

  echo "Node not Ready yet... attempt $i"
  kubectl get nodes || true
  kubectl get pods -A || true
  sleep 10
done

echo "Final cluster status"
kubectl get nodes -o wide || true
kubectl get pods -A || true
kubectl cluster-info || true

echo "==== Kubernetes init completed at $(date) ===="
