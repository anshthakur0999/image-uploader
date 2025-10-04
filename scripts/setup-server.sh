#!/bin/bash

# K3s + Jenkins Installation Script for Ubuntu 22.04
# Run this script on your EC2 instance

set -e

echo "=========================================="
echo "Starting K3s + Jenkins Installation"
echo "=========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if NOT running as root (we need sudo for commands)
if [ "$EUID" -eq 0 ]; then 
    echo -e "${RED}Please do not run this script with sudo. Run it as: ./setup-server.sh${NC}"
    exit 1
fi

# Check if user has sudo privileges
if ! sudo -n true 2>/dev/null; then
    echo -e "${YELLOW}You may be prompted for your password...${NC}"
fi

echo -e "${GREEN}Step 1: Updating system...${NC}"
sudo apt update && sudo apt upgrade -y

echo -e "${GREEN}Step 2: Installing essential tools...${NC}"
sudo apt install -y curl wget git vim unzip htop net-tools

echo -e "${GREEN}Step 3: Installing Docker...${NC}"
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    sudo systemctl enable docker
    sudo systemctl start docker
    rm get-docker.sh
    echo -e "${GREEN}Docker installed successfully${NC}"
else
    echo -e "${YELLOW}Docker already installed${NC}"
fi

echo -e "${GREEN}Step 4: Installing K3s...${NC}"
if ! command -v k3s &> /dev/null; then
    curl -sfL https://get.k3s.io | sh -
    
    # Setup kubectl for current user
    mkdir -p ~/.kube
    sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
    sudo chown $USER:$USER ~/.kube/config
    
    # Add to bashrc
    echo 'export KUBECONFIG=~/.kube/config' >> ~/.bashrc
    echo 'alias kubectl="k3s kubectl"' >> ~/.bashrc
    
    export KUBECONFIG=~/.kube/config
    
    echo -e "${GREEN}K3s installed successfully${NC}"
    
    # Wait for K3s to be ready
    echo "Waiting for K3s to be ready..."
    sleep 10
    sudo k3s kubectl wait --for=condition=Ready nodes --all --timeout=60s
else
    echo -e "${YELLOW}K3s already installed${NC}"
fi

echo -e "${GREEN}Step 5: Installing Java (required for Jenkins)...${NC}"
if ! command -v java &> /dev/null; then
    sudo apt install -y openjdk-17-jre openjdk-17-jdk
    echo -e "${GREEN}Java installed successfully${NC}"
else
    echo -e "${YELLOW}Java already installed${NC}"
fi

echo -e "${GREEN}Step 6: Installing Jenkins...${NC}"
if ! command -v jenkins &> /dev/null; then
    # Add Jenkins repository
    curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee \
        /usr/share/keyrings/jenkins-keyring.asc > /dev/null
    
    echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
        https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
        /etc/apt/sources.list.d/jenkins.list > /dev/null
    
    # Install Jenkins
    sudo apt update
    sudo apt install -y jenkins
    
    # Add jenkins user to docker group
    sudo usermod -aG docker jenkins
    
    # Start Jenkins
    sudo systemctl enable jenkins
    sudo systemctl start jenkins
    
    echo -e "${GREEN}Jenkins installed successfully${NC}"
    
    # Wait for Jenkins to start
    echo "Waiting for Jenkins to start..."
    sleep 30
    
    # Get initial admin password
    if [ -f /var/lib/jenkins/secrets/initialAdminPassword ]; then
        echo -e "${GREEN}=========================================="
        echo "Jenkins Initial Admin Password:"
        sudo cat /var/lib/jenkins/secrets/initialAdminPassword
        echo -e "==========================================${NC}"
    fi
else
    echo -e "${YELLOW}Jenkins already installed${NC}"
fi

echo -e "${GREEN}Step 7: Installing kubectl...${NC}"
if ! command -v kubectl &> /dev/null; then
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm kubectl
    echo -e "${GREEN}kubectl installed successfully${NC}"
else
    echo -e "${YELLOW}kubectl already installed${NC}"
fi

echo -e "${GREEN}Step 8: Installing Helm...${NC}"
if ! command -v helm &> /dev/null; then
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    echo -e "${GREEN}Helm installed successfully${NC}"
else
    echo -e "${YELLOW}Helm already installed${NC}"
fi

echo -e "${GREEN}Step 9: Final configurations...${NC}"

# Reload user groups (you may need to logout and login)
echo -e "${YELLOW}Note: You may need to logout and login again for docker group to take effect${NC}"

echo -e "${GREEN}=========================================="
echo "Installation Complete!"
echo "==========================================${NC}"

echo ""
echo "Next Steps:"
echo "1. Logout and login again to apply docker group changes"
echo "2. Access Jenkins at: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8080"
echo "3. Use the initial admin password above to unlock Jenkins"
echo "4. Install suggested plugins in Jenkins"
echo "5. Configure AWS credentials in your application"
echo ""

echo "Useful Commands:"
echo "  - Check K3s status: sudo systemctl status k3s"
echo "  - Check Jenkins status: sudo systemctl status jenkins"
echo "  - View K3s nodes: kubectl get nodes"
echo "  - View all pods: kubectl get pods -A"
echo ""

echo "System Information:"
echo "  - Docker version: $(docker --version)"
echo "  - K3s version: $(k3s --version | head -n 1)"
echo "  - Jenkins status: $(sudo systemctl is-active jenkins)"
echo "  - Kubectl version: $(kubectl version --client --short 2>/dev/null || echo 'N/A')"
echo ""

echo -e "${GREEN}Setup script completed successfully!${NC}"
