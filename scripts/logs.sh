#!/bin/bash

# View Application Logs
# Usage: ./logs.sh [pod-name]

set -e

NAMESPACE="image-uploader"

if [ -z "$1" ]; then
    # If no pod name provided, show logs from deployment
    echo "Showing logs from deployment/image-uploader..."
    kubectl logs -f deployment/image-uploader -n $NAMESPACE
else
    # Show logs from specific pod
    echo "Showing logs from pod: $1"
    kubectl logs -f $1 -n $NAMESPACE
fi
