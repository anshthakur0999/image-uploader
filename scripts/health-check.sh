#!/bin/bash
# Health check script for the deployment

echo "=== Image Uploader Health Check ==="
echo "Date: $(date)"

# Check K3s service status
echo -e "\n🔧 K3s Service Status:"
sudo systemctl is-active k3s

# Check node status
echo -e "\n🖥️  Node Status:"
kubectl get nodes -o wide

# Check pod status
echo -e "\n📦 Pod Status:"
kubectl get pods -n image-uploader -o wide

# Check pod health details
echo -e "\n❤️  Pod Health Details:"
kubectl get pods -n image-uploader -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.phase}{"\t"}{.status.containerStatuses[0].ready}{"\t"}{.status.containerStatuses[0].restartCount}{"\n"}{end}' | column -t

# Check service endpoints
echo -e "\n🌐 Service Endpoints:"
kubectl get svc -n image-uploader
kubectl get endpoints -n image-uploader

# Check recent pod events
echo -e "\n📰 Recent Events:"
kubectl get events -n image-uploader --sort-by='.lastTimestamp' | tail -10

# Test application endpoint
echo -e "\n🔍 Testing Application Endpoint:"
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:30080)
if [ "$RESPONSE" = "200" ]; then
    echo "✅ Application is responding (HTTP $RESPONSE)"
else
    echo "⚠️  Application issue (HTTP $RESPONSE)"
fi

# Check disk space
echo -e "\n💾 Disk Space:"
df -h / | grep -v Filesystem

# Check memory usage
echo -e "\n🧠 Memory Usage:"
free -h

echo -e "\n✅ Health check complete!"
