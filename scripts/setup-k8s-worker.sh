#!/bin/bash

# AWS EC2 Setup Script for Kubernetes Worker Node
# Run this script on your EC2 instance designated as a Kubernetes worker

set -e

echo "=== Setting up Kubernetes Worker Node on AWS EC2 ==="

# Check if join command is provided
if [ -z "$1" ]; then
    echo "Usage: $0 '<kubeadm join command>'"
    echo "Example: $0 'kubeadm join 10.0.1.100:6443 --token abc123... --discovery-token-ca-cert-hash sha256:...'"
    exit 1
fi

JOIN_COMMAND="$1"

# Update system
echo "Updating system packages..."
sudo apt-get update -y
sudo apt-get upgrade -y

# Install Docker
echo "Installing Docker..."
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# Configure Docker daemon
sudo mkdir -p /etc/docker
cat <<EOF | sudo tee /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

# Start and enable Docker
sudo systemctl daemon-reload
sudo systemctl restart docker
sudo systemctl enable docker
sudo usermod -a -G docker $USER

# Install kubeadm, kubelet, and kubectl
echo "Installing Kubernetes components..."
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update -y
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

# Configure kubelet
echo "Configuring kubelet..."
echo 'KUBELET_EXTRA_ARGS="--cgroup-driver=systemd"' | sudo tee /etc/default/kubelet
sudo systemctl daemon-reload
sudo systemctl restart kubelet

# Disable swap
echo "Disabling swap..."
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# Configure system settings for Kubernetes
echo "Configuring system settings..."
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system

# Join the Kubernetes cluster
echo "Joining Kubernetes cluster..."
echo "Running: sudo $JOIN_COMMAND"
sudo $JOIN_COMMAND

echo "Worker node setup completed!"
echo "The node should now be visible in the cluster."
echo ""
echo "To verify from the master node, run:"
echo "kubectl get nodes"

# Install kubectl completion for worker node (optional)
echo "source <(kubectl completion bash)" >> ~/.bashrc
echo "alias k=kubectl" >> ~/.bashrc
echo "complete -F __start_kubectl k" >> ~/.bashrc

echo "Worker node setup completed successfully!"