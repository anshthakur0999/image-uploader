# Quick Reference - Essential Commands

## 🚀 Deployment Commands

### Initial Setup
```bash
# Clone and setup
git clone https://github.com/anshthakur0999/image-uploader.git
cd image-uploader
pnpm install

# Create EKS cluster
eksctl create cluster --name image-uploader-cluster --region us-east-1 --nodegroup-name image-uploader-nodes --node-type t3.small --nodes 1 --nodes-min 1 --nodes-max 2 --with-oidc --managed

# Deploy to Kubernetes
kubectl apply -f k8s/
```

### Daily Operations
```bash
# Check application status
kubectl get pods -n image-uploader
kubectl logs -f deployment/image-uploader-deployment -n image-uploader

# Get access URL
kubectl get service image-uploader-service -n image-uploader

# Restart deployment
kubectl rollout restart deployment/image-uploader-deployment -n image-uploader
```

### Troubleshooting
```bash
# Debug pod issues
kubectl describe pod POD_NAME -n image-uploader
kubectl get events -n image-uploader --sort-by='.lastTimestamp'

# Check resource usage
kubectl top nodes
kubectl top pods -n image-uploader

# Test Docker image locally
docker pull anshthakur503/image-uploader:latest
docker run -p 3000:3000 anshthakur503/image-uploader:latest
```

### Cleanup
```bash
# Delete deployment
kubectl delete namespace image-uploader

# Delete EKS cluster
eksctl delete cluster --name image-uploader-cluster
```

## 🔧 Key Configuration Values

- **Docker Hub**: `anshthakur503/image-uploader:latest`
- **EKS Cluster**: `image-uploader-cluster` (us-east-1)
- **Node Type**: `t3.small` (1 node)
- **Application Port**: `3000`
- **Service Port**: `80 → 3000`
- **Namespace**: `image-uploader`

## 📱 Quick Health Check

```bash
# One-liner status check
kubectl get all -n image-uploader && echo "--- LoadBalancer URL ---" && kubectl get service image-uploader-service -n image-uploader -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

## 🌐 Your Application URL
**http://ae1a167b4233347bd968540879ee85e2-1516540849.us-east-1.elb.amazonaws.com**