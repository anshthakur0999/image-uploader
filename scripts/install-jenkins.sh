#!/bin/bash

# Jenkins Installation Script for EC2
# This will install Jenkins on your Ubuntu EC2 instance

set -e

echo "=========================================="
echo "Installing Jenkins on EC2"
echo "=========================================="

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}Step 1: Installing Java (required for Jenkins)...${NC}"
if ! command -v java &> /dev/null; then
    sudo apt update
    sudo apt install -y fontconfig openjdk-17-jre
    echo -e "${GREEN}Java installed successfully${NC}"
    java -version
else
    echo -e "${YELLOW}Java already installed${NC}"
    java -version
fi

echo -e "${GREEN}Step 2: Installing Jenkins...${NC}"
if ! command -v jenkins &> /dev/null; then
    # Add Jenkins repository key
    sudo wget -O /usr/share/keyrings/jenkins-keyring.asc \
        https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
    
    # Add Jenkins repository
    echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc]" \
        https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
        /etc/apt/sources.list.d/jenkins.list > /dev/null
    
    # Install Jenkins
    sudo apt update
    sudo apt install -y jenkins
    
    echo -e "${GREEN}Jenkins installed successfully${NC}"
else
    echo -e "${YELLOW}Jenkins already installed${NC}"
fi

echo -e "${GREEN}Step 3: Starting Jenkins service...${NC}"
sudo systemctl enable jenkins
sudo systemctl start jenkins

# Wait for Jenkins to start
echo "Waiting for Jenkins to initialize (this may take 30-60 seconds)..."
sleep 40

echo -e "${GREEN}Step 4: Configuring Jenkins with Docker and kubectl...${NC}"
# Add jenkins user to docker group (if docker is installed)
if command -v docker &> /dev/null; then
    sudo usermod -aG docker jenkins
    echo "Jenkins user added to docker group"
fi

# Give jenkins user access to kubectl
sudo mkdir -p /var/lib/jenkins/.kube
sudo cp /etc/rancher/k3s/k3s.yaml /var/lib/jenkins/.kube/config
sudo chown -R jenkins:jenkins /var/lib/jenkins/.kube
sudo chmod 644 /var/lib/jenkins/.kube/config

echo -e "${GREEN}=========================================="
echo "Jenkins Installation Complete!"
echo "==========================================${NC}"

echo -e "\n${GREEN}Jenkins is running on port 8080${NC}"
echo -e "Access it at: ${YELLOW}http://$(curl -s ifconfig.me):8080${NC}\n"

# Get initial admin password
if [ -f /var/lib/jenkins/secrets/initialAdminPassword ]; then
    echo -e "${GREEN}Initial Admin Password:${NC}"
    sudo cat /var/lib/jenkins/secrets/initialAdminPassword
    echo ""
fi

echo -e "\n${YELLOW}Important:${NC} Make sure port 8080 is open in your EC2 security group!"
echo -e "Run this to check Jenkins status: ${GREEN}sudo systemctl status jenkins${NC}"
