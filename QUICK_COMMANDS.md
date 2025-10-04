# Quick Deployment Commands

## Save this for quick reference during deployment!

---

## 🚀 Initial Setup (One Time)

### 1. Connect to EC2
```bash
ssh -i C:\Users\Ansh\.ssh\image-uploader-key.pem ubuntu@YOUR_EC2_IP
```

### 2. Upload and Run Setup Script
```bash
# From local machine
scp -i C:\Users\Ansh\.ssh\image-uploader-key.pem scripts/setup-server.sh ubuntu@YOUR_EC2_IP:~/

# On EC2
chmod +x setup-server.sh
sudo ./setup-server.sh
```

### 3. Verify Installation
```bash
docker --version
kubectl version --short
kubectl get nodes
```

---

## 📦 Build & Deploy Application

### On Local Machine:

```powershell
# Set your ECR URI (replace with yours!)
$ECR_URI="123456789012.dkr.ecr.us-east-1.amazonaws.com"
$IMAGE_NAME="image-uploader"

# Login to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $ECR_URI

# Build, tag, and push
docker build -t $IMAGE_NAME .
docker tag ${IMAGE_NAME}:latest ${ECR_URI}/${IMAGE_NAME}:latest
docker push ${ECR_URI}/${IMAGE_NAME}:latest
```

### On EC2:

```bash
# Upload k8s files
# (from local machine)
scp -i C:\Users\Ansh\.ssh\image-uploader-key.pem -r k8s ubuntu@YOUR_EC2_IP:~/

# On EC2 - Update secrets first!
nano ~/k8s/secrets.yaml
# Add your AWS credentials

# Update deployment image
nano ~/k8s/deployment.yaml
# Set correct ECR image URI

# Deploy to K3s
kubectl apply -f ~/k8s/namespace.yaml
kubectl apply -f ~/k8s/secrets.yaml
kubectl apply -f ~/k8s/deployment.yaml
kubectl apply -f ~/k8s/service.yaml

# Wait for pods
kubectl get pods -n image-uploader -w
```

---

## 🔍 Monitoring Commands

### Check Application Status
```bash
# View all resources
kubectl get all -n image-uploader

# Check pods
kubectl get pods -n image-uploader

# Check detailed pod info
kubectl describe pod -n image-uploader POD_NAME

# View logs (real-time)
kubectl logs -n image-uploader -l app=image-uploader -f

# View last 50 lines of logs
kubectl logs -n image-uploader -l app=image-uploader --tail=50
```

### Check Resource Usage
```bash
# Node resources
kubectl top nodes

# Pod resources
kubectl top pods -n image-uploader

# Disk usage
df -h
```

---

## 🔄 Update & Restart

### After Code Changes:

```powershell
# On local machine - rebuild and push
docker build -t image-uploader .
docker tag image-uploader:latest $ECR_URI/image-uploader:latest
docker push $ECR_URI/image-uploader:latest
```

```bash
# On EC2 - restart deployment
kubectl rollout restart deployment/image-uploader -n image-uploader

# Watch rollout
kubectl rollout status deployment/image-uploader -n image-uploader

# Verify new pods
kubectl get pods -n image-uploader
```

### Quick Restart (without rebuild):
```bash
kubectl rollout restart deployment/image-uploader -n image-uploader
```

---

## 🧪 Testing Commands

### Test Application Access
```bash
# Get service info
kubectl get svc -n image-uploader

# Test from EC2 itself
curl http://localhost:30080

# Test from outside (use browser)
# http://YOUR_EC2_PUBLIC_IP:30080
```

### Test S3 Connection
```bash
# On EC2
aws s3 ls s3://your-bucket-name/images/
```

---

## 🔧 Troubleshooting Commands

### Pod Issues:
```bash
# Describe pod for events
kubectl describe pod -n image-uploader POD_NAME

# Check previous logs (if pod crashed)
kubectl logs -n image-uploader POD_NAME --previous

# Get into pod shell
kubectl exec -it -n image-uploader POD_NAME -- /bin/sh

# Delete stuck pod
kubectl delete pod -n image-uploader POD_NAME
```

### Service Issues:
```bash
# Check service endpoints
kubectl get endpoints -n image-uploader

# Check service details
kubectl describe svc -n image-uploader image-uploader-service
```

### Secrets Issues:
```bash
# View secrets (base64 encoded)
kubectl get secret -n image-uploader image-uploader-secrets -o yaml

# Decode a secret
kubectl get secret -n image-uploader image-uploader-secrets -o jsonpath='{.data.AWS_REGION}' | base64 -d
```

---

## 🗑️ Cleanup Commands

### Delete Application:
```bash
# Delete all resources in namespace
kubectl delete namespace image-uploader

# Or delete individually
kubectl delete -f ~/k8s/service.yaml
kubectl delete -f ~/k8s/deployment.yaml
kubectl delete -f ~/k8s/secrets.yaml
kubectl delete -f ~/k8s/namespace.yaml
```

### Cleanup Docker:
```bash
# Remove unused images
sudo docker image prune -a

# Remove all stopped containers
sudo docker container prune

# Check disk space
sudo docker system df
```

---

## 📊 Jenkins Commands

### Jenkins Service:
```bash
# Status
sudo systemctl status jenkins

# Restart
sudo systemctl restart jenkins

# View logs
sudo journalctl -u jenkins -f

# Get initial password
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

### Jenkins User Permissions:
```bash
# Add jenkins to docker group
sudo usermod -aG docker jenkins

# Restart Jenkins after group change
sudo systemctl restart jenkins
```

---

## 🔐 Security Group Quick Reference

### Required Ports:
- **22** (SSH) - Your IP only
- **80** (HTTP) - 0.0.0.0/0
- **443** (HTTPS) - 0.0.0.0/0
- **8080** (Jenkins) - Your IP only
- **30080** (K3s NodePort) - 0.0.0.0/0

---

## 📝 Environment Variables Reference

### In K8s secrets.yaml:
```yaml
AWS_REGION: "us-east-1"
AWS_ACCESS_KEY_ID: "AKIAXXXXXXXXXXXXX"
AWS_SECRET_ACCESS_KEY: "xxxxxxxxxxxxxxxxxxxx"
AWS_S3_BUCKET_NAME: "image-uploader-yourname-20251004"
NEXT_PUBLIC_API_URL: "http://YOUR_EC2_PUBLIC_IP:30080"
```

---

## 🎯 Common Tasks

### View Application URL:
```bash
echo "Application URL: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):30080"
```

### Check All Application Components:
```bash
echo "=== Pods ==="
kubectl get pods -n image-uploader
echo -e "\n=== Services ==="
kubectl get svc -n image-uploader
echo -e "\n=== Recent Logs ==="
kubectl logs -n image-uploader -l app=image-uploader --tail=10
```

### Quick Health Check:
```bash
#!/bin/bash
echo "Checking application health..."
kubectl get pods -n image-uploader | grep Running && echo "✅ Pods running" || echo "❌ Pods not running"
curl -s http://localhost:30080 > /dev/null && echo "✅ Application accessible" || echo "❌ Application not accessible"
aws s3 ls s3://$(kubectl get secret -n image-uploader image-uploader-secrets -o jsonpath='{.data.AWS_S3_BUCKET_NAME}' | base64 -d)/images/ > /dev/null 2>&1 && echo "✅ S3 accessible" || echo "❌ S3 not accessible"
```

---

## 💡 Pro Tips

1. **Save your EC2 IP:** Add it to your hosts file or bookmark it
2. **Use kubectl alias:** `alias k=kubectl` to save typing
3. **Watch deployments:** Use `-w` flag with get commands for real-time updates
4. **Keep logs:** Jenkins and kubectl logs are your best friends for debugging
5. **Regular backups:** Back up your K8s manifests and Jenkins config

---

## 🚨 Emergency Commands

### Application Down:
```bash
# Quick restart
kubectl rollout restart deployment/image-uploader -n image-uploader
kubectl get pods -n image-uploader -w
```

### Out of Memory:
```bash
# Check memory
free -h
# Clear cache
sudo sh -c 'echo 3 > /proc/sys/vm/drop_caches'
# Restart if needed
sudo reboot
```

### Disk Full:
```bash
# Check disk space
df -h
# Clean Docker
sudo docker system prune -a --volumes
# Clean apt cache
sudo apt clean
```

---

## 📞 Need Help?

Check these in order:
1. Pod logs: `kubectl logs -n image-uploader -l app=image-uploader --tail=100`
2. Pod events: `kubectl describe pod -n image-uploader POD_NAME`
3. Service status: `kubectl get svc -n image-uploader`
4. EC2 security groups: Check ports are open
5. S3 permissions: Verify IAM user has access
6. AWS credentials: Check secrets are correct

---

Save this file and refer to it during deployment! 🚀
