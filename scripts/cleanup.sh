#!/bin/bash

# Clean up all resources
# WARNING: This will delete everything related to the image-uploader application

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${RED}=========================================="
echo "WARNING: This will delete all image-uploader resources"
echo -e "==========================================${NC}"

read -p "Are you sure you want to continue? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Cleanup cancelled."
    exit 0
fi

echo -e "${GREEN}Deleting Kubernetes resources...${NC}"

kubectl delete ingress image-uploader-ingress -n image-uploader --ignore-not-found=true
kubectl delete service image-uploader-service -n image-uploader --ignore-not-found=true
kubectl delete deployment image-uploader -n image-uploader --ignore-not-found=true
kubectl delete configmap app-config -n image-uploader --ignore-not-found=true
kubectl delete secret aws-credentials -n image-uploader --ignore-not-found=true

echo -e "${YELLOW}Waiting for pods to terminate...${NC}"
sleep 5

echo -e "${GREEN}Deleting namespace...${NC}"
kubectl delete namespace image-uploader --ignore-not-found=true

echo -e "${GREEN}Cleanup complete!${NC}"
