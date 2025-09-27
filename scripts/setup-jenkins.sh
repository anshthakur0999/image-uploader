#!/bin/bash

# Jenkins Installation Script for AWS EC2
# This script installs Jenkins with necessary plugins for CI/CD

set -e

echo "=== Installing Jenkins on AWS EC2 ==="

# Update system
echo "Updating system packages..."
sudo apt-get update -y
sudo apt-get upgrade -y

# Install Java (required for Jenkins)
echo "Installing Java..."
sudo apt-get install -y openjdk-11-jdk

# Install Docker (for building images)
echo "Installing Docker..."
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# Start and enable Docker
sudo systemctl start docker
sudo systemctl enable docker

# Install kubectl (for Kubernetes deployments)
echo "Installing kubectl..."
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update -y
sudo apt-get install -y kubectl

# Install Node.js and pnpm (for building Next.js app)
echo "Installing Node.js and pnpm..."
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs
sudo npm install -g pnpm

# Install Jenkins
echo "Installing Jenkins..."
wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add -
sudo sh -c 'echo deb https://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
sudo apt-get update -y
sudo apt-get install -y jenkins

# Add jenkins user to docker group
sudo usermod -a -G docker jenkins

# Start and enable Jenkins
sudo systemctl start jenkins
sudo systemctl enable jenkins

# Configure firewall (if UFW is enabled)
if sudo ufw status | grep -q "Status: active"; then
    echo "Configuring firewall..."
    sudo ufw allow 8080
    sudo ufw allow OpenSSH
fi

# Get Jenkins initial admin password
echo "Waiting for Jenkins to start..."
sleep 30

JENKINS_PASSWORD=$(sudo cat /var/lib/jenkins/secrets/initialAdminPassword)

echo "========================================"
echo "Jenkins Installation Complete!"
echo "========================================"
echo ""
echo "Access Jenkins at: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8080"
echo ""
echo "Initial Admin Password: $JENKINS_PASSWORD"
echo ""
echo "========================================"
echo "Post-Installation Setup:"
echo "========================================"
echo "1. Access Jenkins web interface"
echo "2. Use the admin password above"
echo "3. Install suggested plugins"
echo "4. Create an admin user"
echo "5. Configure the following plugins:"
echo "   - Docker Pipeline"
echo "   - Kubernetes"
echo "   - Git"
echo "   - NodeJS"
echo "   - Blue Ocean (optional)"
echo ""
echo "========================================"
echo "Required Credentials to Configure:"
echo "========================================"
echo "1. DockerHub credentials (dockerhub-credentials)"
echo "2. Kubeconfig file (kubeconfig-file)"
echo "3. AWS credentials (aws-credentials)"
echo "4. Git repository credentials (if private repo)"
echo ""
echo "Jenkins service status:"
sudo systemctl status jenkins --no-pager

# Create Jenkins CLI alias
echo "alias jenkins-cli='java -jar /var/cache/jenkins/war/WEB-INF/jenkins-cli.jar -s http://localhost:8080/'" >> ~/.bashrc

echo ""
echo "Setup completed! Remember to:"
echo "1. Configure security groups to allow port 8080"
echo "2. Set up SSL/HTTPS for production use"
echo "3. Configure backup strategy for Jenkins data"
echo "4. Set up monitoring and alerts"