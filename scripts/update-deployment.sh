#!/bin/bash

# Update Kubernetes Deployment with New Image
# Usage: ./update-deployment.sh [image-tag]

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

IMAGE_TAG=${1:-latest}

echo -e "${GREEN}Updating deployment with image tag: ${IMAGE_TAG}${NC}"

# Update the image in the deployment
kubectl set image deployment/image-uploader \
    image-uploader=your-dockerhub-username/image-uploader:${IMAGE_TAG} \
    -n image-uploader

echo -e "${GREEN}Waiting for rollout to complete...${NC}"
kubectl rollout status deployment/image-uploader -n image-uploader --timeout=5m

echo -e "${GREEN}Deployment updated successfully!${NC}"

# Show current pods
kubectl get pods -n image-uploader
