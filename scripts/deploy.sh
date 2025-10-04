#!/bin/bash

# Quick Deploy Script for Image Uploader Application
# This script deploys the application to an existing K3s cluster

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=========================================="
echo "Image Uploader - Quick Deploy"
echo "=========================================="

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}kubectl is not installed. Please install kubectl first.${NC}"
    exit 1
fi

# Get user inputs
read -p "Enter your Docker Hub username: " DOCKER_USERNAME
read -p "Enter your AWS S3 bucket name: " S3_BUCKET
read -p "Enter your AWS region (default: us-east-1): " AWS_REGION
AWS_REGION=${AWS_REGION:-us-east-1}
read -p "Enter your AWS Access Key ID: " AWS_ACCESS_KEY
read -sp "Enter your AWS Secret Access Key: " AWS_SECRET_KEY
echo ""

echo -e "${GREEN}Step 1: Building Docker image...${NC}"
docker build -t ${DOCKER_USERNAME}/image-uploader:latest .

echo -e "${GREEN}Step 2: Pushing to Docker Hub...${NC}"
docker login
docker push ${DOCKER_USERNAME}/image-uploader:latest

echo -e "${GREEN}Step 3: Creating namespace...${NC}"
kubectl create namespace image-uploader --dry-run=client -o yaml | kubectl apply -f -

echo -e "${GREEN}Step 4: Creating secrets...${NC}"
kubectl create secret generic aws-credentials \
    --from-literal=AWS_REGION=${AWS_REGION} \
    --from-literal=AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY} \
    --from-literal=AWS_SECRET_ACCESS_KEY=${AWS_SECRET_KEY} \
    --from-literal=AWS_S3_BUCKET_NAME=${S3_BUCKET} \
    --namespace=image-uploader \
    --dry-run=client -o yaml | kubectl apply -f -

echo -e "${GREEN}Step 5: Creating ConfigMap...${NC}"
kubectl create configmap app-config \
    --from-literal=NEXT_PUBLIC_API_URL=http://localhost:30080 \
    --from-literal=NODE_ENV=production \
    --namespace=image-uploader \
    --dry-run=client -o yaml | kubectl apply -f -

echo -e "${GREEN}Step 6: Updating deployment image...${NC}"
# Update the deployment file with the correct image
sed "s|your-dockerhub-username/image-uploader:latest|${DOCKER_USERNAME}/image-uploader:latest|g" \
    k8s/01-deployment.yaml > /tmp/deployment-updated.yaml

echo -e "${GREEN}Step 7: Applying Kubernetes manifests...${NC}"
kubectl apply -f /tmp/deployment-updated.yaml
kubectl apply -f k8s/02-service.yaml
kubectl apply -f k8s/03-ingress.yaml

echo -e "${GREEN}Step 8: Waiting for deployment to be ready...${NC}"
kubectl wait --for=condition=available --timeout=300s \
    deployment/image-uploader -n image-uploader

echo -e "${GREEN}Step 9: Getting service information...${NC}"
kubectl get pods -n image-uploader
kubectl get services -n image-uploader

# Get NodePort
NODE_PORT=$(kubectl get svc image-uploader-service -n image-uploader -o jsonpath='{.spec.ports[0].nodePort}')

echo ""
echo -e "${GREEN}=========================================="
echo "Deployment Complete!"
echo -e "==========================================${NC}"
echo ""
echo "Application is now running!"
echo "Access URL: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || hostname -I | awk '{print $1}'):${NODE_PORT}"
echo ""
echo "Useful commands:"
echo "  - View pods: kubectl get pods -n image-uploader"
echo "  - View logs: kubectl logs -f deployment/image-uploader -n image-uploader"
echo "  - Scale app: kubectl scale deployment/image-uploader --replicas=3 -n image-uploader"
echo ""
