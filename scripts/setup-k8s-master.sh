#!/bin/bash

# AWS EC2 Setup Script for Kubernetes Master Node
# Run this script on your EC2 instance designated as the Kubernetes master

set -e

echo "=== Setting up Kubernetes Master Node on AWS EC2 ==="

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

# Initialize Kubernetes cluster
echo "Initializing Kubernetes cluster..."
MASTER_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
sudo kubeadm init --apiserver-advertise-address=$MASTER_IP --pod-network-cidr=10.244.0.0/16

# Configure kubectl for the user
echo "Configuring kubectl..."
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Install Flannel network plugin
echo "Installing Flannel network plugin..."
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml

# Install NGINX Ingress Controller
echo "Installing NGINX Ingress Controller..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/cloud/deploy.yaml

# Wait for ingress controller to be ready
echo "Waiting for NGINX Ingress Controller to be ready..."
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=300s

# Install metrics server for HPA
echo "Installing metrics server..."
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Create join command for worker nodes
echo "Generating join command for worker nodes..."
JOIN_COMMAND=$(sudo kubeadm token create --print-join-command)
echo "Save this command to join worker nodes:"
echo "================================="
echo "$JOIN_COMMAND"
echo "================================="

# Save join command to file
echo "$JOIN_COMMAND" > ~/worker-join-command.txt
chmod 600 ~/worker-join-command.txt

# Display cluster status
echo "Kubernetes cluster setup completed!"
echo "Cluster status:"
kubectl get nodes
kubectl get pods --all-namespaces

echo ""
echo "Next steps:"
echo "1. Run the worker node setup script on your worker EC2 instance"
echo "2. Use the join command saved in ~/worker-join-command.txt"
echo "3. Configure your security groups to allow:"
echo "   - Port 6443 (Kubernetes API)"
echo "   - Port 10250 (Kubelet)"
echo "   - Port 10251 (kube-scheduler)"
echo "   - Port 10252 (kube-controller-manager)"
echo "   - Port 2379-2380 (etcd)"
echo "   - Port 80,443 (HTTP/HTTPS)"
echo "4. Set up DNS or load balancer for external access"

# Install kubectl completion
echo "source <(kubectl completion bash)" >> ~/.bashrc
echo "alias k=kubectl" >> ~/.bashrc
echo "complete -F __start_kubectl k" >> ~/.bashrc

echo "Master node setup completed successfully!"