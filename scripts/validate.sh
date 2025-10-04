#!/bin/bash

# Pre-deployment Validation Script
# Run this to check if everything is configured correctly before deploying

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

ERRORS=0
WARNINGS=0

echo -e "${BLUE}=========================================="
echo "Pre-Deployment Validation"
echo -e "==========================================${NC}"
echo ""

# Function to check command
check_command() {
    if command -v $1 &> /dev/null; then
        echo -e "${GREEN}✓${NC} $1 is installed"
        return 0
    else
        echo -e "${RED}✗${NC} $1 is NOT installed"
        ERRORS=$((ERRORS + 1))
        return 1
    fi
}

# Function to check file
check_file() {
    if [ -f "$1" ]; then
        echo -e "${GREEN}✓${NC} File exists: $1"
        return 0
    else
        echo -e "${RED}✗${NC} File missing: $1"
        ERRORS=$((ERRORS + 1))
        return 1
    fi
}

# Function to check directory
check_directory() {
    if [ -d "$1" ]; then
        echo -e "${GREEN}✓${NC} Directory exists: $1"
        return 0
    else
        echo -e "${RED}✗${NC} Directory missing: $1"
        ERRORS=$((ERRORS + 1))
        return 1
    fi
}

# Function to check environment variable in file
check_env_var() {
    local file=$1
    local var=$2
    
    if [ -f "$file" ]; then
        if grep -q "$var" "$file"; then
            local value=$(grep "$var" "$file" | cut -d':' -f2 | tr -d ' "')
            if [ "$value" != "your-"* ] && [ "$value" != "" ]; then
                echo -e "${GREEN}✓${NC} $var is configured in $file"
                return 0
            else
                echo -e "${YELLOW}⚠${NC} $var needs to be updated in $file"
                WARNINGS=$((WARNINGS + 1))
                return 1
            fi
        else
            echo -e "${RED}✗${NC} $var not found in $file"
            ERRORS=$((ERRORS + 1))
            return 1
        fi
    else
        echo -e "${RED}✗${NC} File not found: $file"
        ERRORS=$((ERRORS + 1))
        return 1
    fi
}

echo "Checking system requirements..."
echo "-----------------------------------"
check_command docker
check_command kubectl
check_command node
check_command npm

echo ""
echo "Checking Kubernetes cluster..."
echo "-----------------------------------"
if kubectl cluster-info &> /dev/null; then
    echo -e "${GREEN}✓${NC} Kubernetes cluster is accessible"
    kubectl get nodes
else
    echo -e "${RED}✗${NC} Cannot connect to Kubernetes cluster"
    ERRORS=$((ERRORS + 1))
fi

echo ""
echo "Checking required files..."
echo "-----------------------------------"
check_file "Dockerfile"
check_file "Jenkinsfile"
check_file "package.json"
check_file "next.config.mjs"
check_directory "k8s"
check_file "k8s/00-namespace-secrets.yaml"
check_file "k8s/01-deployment.yaml"
check_file "k8s/02-service.yaml"
check_file "k8s/03-ingress.yaml"

echo ""
echo "Checking AWS configuration in Kubernetes secrets..."
echo "-----------------------------------"
check_env_var "k8s/00-namespace-secrets.yaml" "AWS_REGION"
check_env_var "k8s/00-namespace-secrets.yaml" "AWS_ACCESS_KEY_ID"
check_env_var "k8s/00-namespace-secrets.yaml" "AWS_SECRET_ACCESS_KEY"
check_env_var "k8s/00-namespace-secrets.yaml" "AWS_S3_BUCKET_NAME"

echo ""
echo "Checking Docker image configuration..."
echo "-----------------------------------"
if grep -q "your-dockerhub-username" k8s/01-deployment.yaml; then
    echo -e "${YELLOW}⚠${NC} Docker Hub username needs to be updated in k8s/01-deployment.yaml"
    WARNINGS=$((WARNINGS + 1))
else
    echo -e "${GREEN}✓${NC} Docker image name configured in deployment"
fi

if grep -q "your-dockerhub-username" Jenkinsfile; then
    echo -e "${YELLOW}⚠${NC} Docker Hub username needs to be updated in Jenkinsfile"
    WARNINGS=$((WARNINGS + 1))
else
    echo -e "${GREEN}✓${NC} Docker image name configured in Jenkinsfile"
fi

echo ""
echo "Checking npm dependencies..."
echo "-----------------------------------"
if [ -d "node_modules" ]; then
    echo -e "${GREEN}✓${NC} node_modules directory exists"
else
    echo -e "${YELLOW}⚠${NC} node_modules not found. Run: npm install"
    WARNINGS=$((WARNINGS + 1))
fi

if [ -f "package-lock.json" ] || [ -f "pnpm-lock.yaml" ]; then
    echo -e "${GREEN}✓${NC} Lock file exists"
else
    echo -e "${YELLOW}⚠${NC} No lock file found"
    WARNINGS=$((WARNINGS + 1))
fi

echo ""
echo "Checking environment configuration..."
echo "-----------------------------------"
if [ -f ".env" ]; then
    echo -e "${GREEN}✓${NC} .env file exists"
else
    echo -e "${YELLOW}⚠${NC} .env file not found. Copy from .env.example for local development"
    WARNINGS=$((WARNINGS + 1))
fi

if [ -f ".env.example" ]; then
    echo -e "${GREEN}✓${NC} .env.example file exists"
else
    echo -e "${YELLOW}⚠${NC} .env.example file not found"
    WARNINGS=$((WARNINGS + 1))
fi

echo ""
echo "Checking Docker configuration..."
echo "-----------------------------------"
if docker ps &> /dev/null; then
    echo -e "${GREEN}✓${NC} Docker is running"
else
    echo -e "${RED}✗${NC} Docker is not running or user doesn't have permission"
    ERRORS=$((ERRORS + 1))
fi

if [ -f ".dockerignore" ]; then
    echo -e "${GREEN}✓${NC} .dockerignore file exists"
else
    echo -e "${YELLOW}⚠${NC} .dockerignore file not found"
    WARNINGS=$((WARNINGS + 1))
fi

echo ""
echo "Checking scripts..."
echo "-----------------------------------"
check_directory "scripts"
if [ -d "scripts" ]; then
    for script in scripts/*.sh; do
        if [ -x "$script" ]; then
            echo -e "${GREEN}✓${NC} $script is executable"
        else
            echo -e "${YELLOW}⚠${NC} $script is not executable. Run: chmod +x $script"
            WARNINGS=$((WARNINGS + 1))
        fi
    done
fi

echo ""
echo "Testing Docker build..."
echo "-----------------------------------"
echo "Attempting to build Docker image (this may take a few minutes)..."
if docker build -t validation-test:latest . &> /dev/null; then
    echo -e "${GREEN}✓${NC} Docker build successful"
    docker rmi validation-test:latest &> /dev/null
else
    echo -e "${RED}✗${NC} Docker build failed. Check Dockerfile and dependencies"
    ERRORS=$((ERRORS + 1))
fi

echo ""
echo "Checking AWS CLI (optional)..."
echo "-----------------------------------"
if command -v aws &> /dev/null; then
    echo -e "${GREEN}✓${NC} AWS CLI is installed"
    
    # Check if credentials are configured
    if aws sts get-caller-identity &> /dev/null; then
        echo -e "${GREEN}✓${NC} AWS credentials are configured"
    else
        echo -e "${YELLOW}⚠${NC} AWS credentials not configured or invalid"
        WARNINGS=$((WARNINGS + 1))
    fi
else
    echo -e "${YELLOW}⚠${NC} AWS CLI not installed (optional, but recommended)"
    WARNINGS=$((WARNINGS + 1))
fi

echo ""
echo "Checking Jenkins configuration (if running locally)..."
echo "-----------------------------------"
if curl -s http://localhost:8080 &> /dev/null; then
    echo -e "${GREEN}✓${NC} Jenkins is accessible at http://localhost:8080"
else
    echo -e "${YELLOW}⚠${NC} Jenkins not accessible at http://localhost:8080 (may be on remote server)"
    WARNINGS=$((WARNINGS + 1))
fi

echo ""
echo "Checking Kubernetes resources..."
echo "-----------------------------------"
if kubectl get namespace image-uploader &> /dev/null; then
    echo -e "${GREEN}✓${NC} Namespace 'image-uploader' exists"
    
    if kubectl get deployment image-uploader -n image-uploader &> /dev/null; then
        echo -e "${GREEN}✓${NC} Deployment 'image-uploader' exists"
    else
        echo -e "${YELLOW}⚠${NC} Deployment not yet created (expected for first deployment)"
    fi
else
    echo -e "${YELLOW}⚠${NC} Namespace 'image-uploader' not created yet (expected for first deployment)"
fi

echo ""
echo -e "${BLUE}=========================================="
echo "Validation Summary"
echo -e "==========================================${NC}"
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✓ All checks passed!${NC}"
    echo ""
    echo "You're ready to deploy!"
    echo ""
    echo "Next steps:"
    echo "1. Review DEPLOYMENT.md for detailed instructions"
    echo "2. Update any remaining configuration values"
    echo "3. Run: ./scripts/deploy.sh"
    echo "   OR push to GitHub to trigger Jenkins pipeline"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠ $WARNINGS warning(s) found${NC}"
    echo ""
    echo "You can proceed, but consider addressing the warnings above."
    echo ""
    echo "Next steps:"
    echo "1. Review and fix warnings (optional)"
    echo "2. Run: ./scripts/deploy.sh"
    exit 0
else
    echo -e "${RED}✗ $ERRORS error(s) found${NC}"
    if [ $WARNINGS -gt 0 ]; then
        echo -e "${YELLOW}⚠ $WARNINGS warning(s) found${NC}"
    fi
    echo ""
    echo "Please fix the errors above before deploying."
    echo ""
    echo "Common fixes:"
    echo "- Run: npm install"
    echo "- Update AWS credentials in k8s/00-namespace-secrets.yaml"
    echo "- Update Docker Hub username in k8s/01-deployment.yaml and Jenkinsfile"
    echo "- Make scripts executable: chmod +x scripts/*.sh"
    echo "- Start Docker: sudo systemctl start docker"
    exit 1
fi
