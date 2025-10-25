#!/bin/bash

# Service Management Script for t3.small optimization
# Helps manage Jenkins and other services to save memory

case "$1" in
    status)
        echo "=== System Resources ==="
        free -h
        echo ""
        echo "=== Running Services ==="
        echo "Jenkins: $(sudo systemctl is-active jenkins)"
        echo "K3s: $(sudo systemctl is-active k3s)"
        echo ""
        echo "=== Pod Status ==="
        kubectl get pods -n image-uploader
        ;;
    
    jenkins-stop)
        echo "Stopping Jenkins to free memory..."
        sudo systemctl stop jenkins
        echo "Jenkins stopped. Memory freed:"
        free -h | grep Mem
        ;;
    
    jenkins-start)
        echo "Starting Jenkins..."
        sudo systemctl start jenkins
        echo "Waiting for Jenkins to be ready (30s)..."
        sleep 30
        echo "Jenkins started!"
        ;;
    
    optimize)
        echo "Optimizing for low memory..."
        
        # Stop Jenkins if not needed
        read -p "Stop Jenkins to save ~500MB RAM? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            sudo systemctl stop jenkins
            echo "✓ Jenkins stopped"
        fi
        
        # Scale down to 1 replica
        kubectl scale deployment image-uploader --replicas=1 -n image-uploader
        echo "✓ Scaled down to 1 pod"
        
        # Show results
        echo ""
        echo "=== Memory Status ==="
        free -h
        ;;
    
    scale-up)
        echo "Scaling back up (requires more memory)..."
        kubectl scale deployment image-uploader --replicas=2 -n image-uploader
        echo "✓ Scaled up to 2 pods"
        kubectl get pods -n image-uploader
        ;;
    
    *)
        echo "Usage: $0 {status|jenkins-stop|jenkins-start|optimize|scale-up}"
        echo ""
        echo "Commands:"
        echo "  status        - Show system resources and service status"
        echo "  jenkins-stop  - Stop Jenkins to save ~500MB RAM"
        echo "  jenkins-start - Start Jenkins again"
        echo "  optimize      - Optimize system for low memory (stop Jenkins, scale down)"
        echo "  scale-up      - Scale back up to 2 pods"
        exit 1
        ;;
esac
