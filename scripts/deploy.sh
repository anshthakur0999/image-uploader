#!/bin/bash

# Deployment helper script
# This script helps deploy or update the application

set -e

# Configuration
NAMESPACE="image-uploader"
DEPLOYMENT_NAME="image-uploader-deployment"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_prerequisites() {
    log_info "Checking prerequisites..."
    
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl is not installed"
        exit 1
    fi
    
    if ! kubectl cluster-info &> /dev/null; then
        log_error "kubectl is not configured or cluster is not accessible"
        exit 1
    fi
    
    log_info "Prerequisites check passed"
}

deploy_application() {
    local image_tag=${1:-latest}
    
    log_info "Deploying application with image tag: $image_tag"
    
    # Set environment variables for envsubst
    export IMAGE_NAME=${IMAGE_NAME:-"your-dockerhub-username/image-uploader"}
    export IMAGE_TAG=$image_tag
    
    # Apply Kubernetes manifests
    log_info "Creating namespace..."
    kubectl apply -f k8s/namespace.yaml
    
    log_info "Applying configuration..."
    kubectl apply -f k8s/configmap.yaml
    kubectl apply -f k8s/pvc.yaml
    
    log_info "Deploying application..."
    envsubst < k8s/deployment.yaml | kubectl apply -f -
    kubectl apply -f k8s/service.yaml
    
    # Wait for deployment
    log_info "Waiting for deployment to complete..."
    kubectl rollout status deployment/$DEPLOYMENT_NAME -n $NAMESPACE --timeout=300s
    
    log_info "Deployment completed successfully!"
}

get_service_url() {
    log_info "Getting service URL..."
    
    # Wait a bit for LoadBalancer to be provisioned
    sleep 10
    
    EXTERNAL_IP=$(kubectl get service image-uploader-service -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
    
    if [ -z "$EXTERNAL_IP" ]; then
        log_warn "LoadBalancer IP not yet available. You can check later with:"
        echo "kubectl get service image-uploader-service -n $NAMESPACE"
    else
        log_info "Application is available at: http://$EXTERNAL_IP"
    fi
}

check_health() {
    log_info "Checking application health..."
    
    # Get pod status
    kubectl get pods -n $NAMESPACE -l app=image-uploader
    
    # Check if pods are ready
    kubectl wait --for=condition=ready pod -l app=image-uploader -n $NAMESPACE --timeout=60s
    
    log_info "Health check completed"
}

rollback() {
    log_warn "Rolling back to previous version..."
    kubectl rollout undo deployment/$DEPLOYMENT_NAME -n $NAMESPACE
    kubectl rollout status deployment/$DEPLOYMENT_NAME -n $NAMESPACE --timeout=300s
    log_info "Rollback completed"
}

cleanup() {
    log_warn "Cleaning up resources..."
    kubectl delete namespace $NAMESPACE --ignore-not-found=true
    log_info "Cleanup completed"
}

show_logs() {
    log_info "Showing application logs..."
    kubectl logs -f deployment/$DEPLOYMENT_NAME -n $NAMESPACE
}

# Main script
case "${1:-deploy}" in
    "deploy")
        check_prerequisites
        deploy_application "${2:-latest}"
        get_service_url
        check_health
        ;;
    "status")
        check_prerequisites
        check_health
        get_service_url
        ;;
    "logs")
        check_prerequisites
        show_logs
        ;;
    "rollback")
        check_prerequisites
        rollback
        ;;
    "cleanup")
        check_prerequisites
        cleanup
        ;;
    "help"|"--help"|"-h")
        echo "Usage: $0 [command] [options]"
        echo ""
        echo "Commands:"
        echo "  deploy [tag]  Deploy application (default: latest)"
        echo "  status        Check application status"
        echo "  logs          Show application logs"
        echo "  rollback      Rollback to previous version"
        echo "  cleanup       Delete all resources"
        echo "  help          Show this help message"
        ;;
    *)
        log_error "Unknown command: $1"
        echo "Use '$0 help' for usage information"
        exit 1
        ;;
esac