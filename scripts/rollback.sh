#!/bin/bash

# Rollback Deployment Script
# Usage: ./rollback.sh [revision-number]

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}Rollout History:${NC}"
kubectl rollout history deployment/image-uploader -n image-uploader

if [ -z "$1" ]; then
    echo -e "${GREEN}Rolling back to previous version...${NC}"
    kubectl rollout undo deployment/image-uploader -n image-uploader
else
    echo -e "${GREEN}Rolling back to revision: $1${NC}"
    kubectl rollout undo deployment/image-uploader --to-revision=$1 -n image-uploader
fi

echo -e "${GREEN}Waiting for rollback to complete...${NC}"
kubectl rollout status deployment/image-uploader -n image-uploader --timeout=5m

echo -e "${GREEN}Rollback completed successfully!${NC}"

# Show current pods
kubectl get pods -n image-uploader
