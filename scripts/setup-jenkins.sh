#!/bin/bash

# Jenkins Setup Script for AWS EC2 Free Tier
# This script installs Jenkins on an Ubuntu EC2 instance

set -e

echo "🚀 Installing Jenkins on AWS EC2..."

# Update system
sudo apt update && sudo apt upgrade -y

# Install Java 11 (required for Jenkins)
sudo apt install -y openjdk-11-jdk

# Add Jenkins repository
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee \
    /usr/share/keyrings/jenkins-keyring.asc > /dev/null

echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
    https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
    /etc/apt/sources.list.d/jenkins.list > /dev/null

# Install Jenkins
sudo apt update
sudo apt install -y jenkins

# Start and enable Jenkins
sudo systemctl start jenkins
sudo systemctl enable jenkins

# Install Docker
sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io

# Add jenkins user to docker group
sudo usermod -aG docker jenkins

# Install Node.js and pnpm
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs
sudo npm install -g pnpm

# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Install kubectl
sudo curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo chmod +x kubectl
sudo mv kubectl /usr/local/bin/

# Install eksctl
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin

# Install Trivy for security scanning
sudo apt-get update
sudo apt-get install -y wget apt-transport-https gnupg lsb-release
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list
sudo apt-get update
sudo apt-get install -y trivy

# Restart Jenkins to apply group changes
sudo systemctl restart jenkins

# Get Jenkins initial admin password
echo "✅ Jenkins installation completed!"
echo "🔐 Initial admin password:"
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
echo ""
echo "🌐 Access Jenkins at: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8080"
echo ""
echo "📋 Required Jenkins plugins to install:"
echo "- Pipeline"
echo "- Docker Pipeline"
echo "- Kubernetes CLI"
echo "- AWS Steps"
echo "- Blue Ocean (optional)"
echo ""
echo "🔧 Next steps:"
echo "1. Complete Jenkins setup wizard"
echo "2. Install required plugins"
echo "3. Add credentials for Docker Hub and AWS"
echo "4. Create a new Pipeline job"
echo "5. Configure webhook for automatic builds"