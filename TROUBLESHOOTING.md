# Troubleshooting Guide

## Common Issues and Solutions

### 1. Pod Creation Issues

#### Issue: Pods stuck in `Pending` state
```bash
kubectl describe pod <pod-name> -n image-uploader
```

**Possible Causes:**
- Insufficient resources on the node
- Image pull issues
- Volume mounting problems

**Solutions:**
```bash
# Check node resources
kubectl top nodes

# Check events
kubectl get events -n image-uploader --sort-by='.lastTimestamp'

# If resource issue, reduce requests in deployment:
kubectl edit deployment image-uploader -n image-uploader
```

#### Issue: Pods in `ImagePullBackOff` or `ErrImagePull`
```bash
kubectl describe pod <pod-name> -n image-uploader
```

**Solutions:**
```bash
# 1. Verify image exists on Docker Hub
docker pull your-username/image-uploader:latest

# 2. Check image name in deployment
kubectl get deployment image-uploader -n image-uploader -o yaml | grep image:

# 3. If private registry, add image pull secret
kubectl create secret docker-registry dockerhub-secret \
  --docker-server=docker.io \
  --docker-username=your-username \
  --docker-password=your-password \
  --docker-email=your-email \
  -n image-uploader

# Update deployment to use secret
kubectl patch deployment image-uploader -n image-uploader \
  -p '{"spec":{"template":{"spec":{"imagePullSecrets":[{"name":"dockerhub-secret"}]}}}}'
```

#### Issue: Pods in `CrashLoopBackOff`
```bash
kubectl logs <pod-name> -n image-uploader
kubectl logs <pod-name> -n image-uploader --previous
```

**Common Causes:**
- Application startup errors
- Missing environment variables
- AWS credentials issues
- Port conflicts

**Solutions:**
```bash
# Check environment variables
kubectl exec <pod-name> -n image-uploader -- env

# Verify AWS credentials
kubectl get secret aws-credentials -n image-uploader -o yaml

# Check application logs
kubectl logs -f <pod-name> -n image-uploader
```

### 2. AWS S3 Connection Issues

#### Issue: Cannot upload to S3
**Error:** `AccessDenied` or `NoSuchBucket`

**Solutions:**
```bash
# 1. Verify bucket exists
aws s3 ls s3://your-bucket-name

# 2. Verify IAM permissions
aws s3api get-bucket-policy --bucket your-bucket-name

# 3. Test credentials locally
aws s3 cp test.txt s3://your-bucket-name/test.txt \
  --region us-east-1 \
  --profile your-profile

# 4. Update secrets in K8s
kubectl delete secret aws-credentials -n image-uploader
kubectl create secret generic aws-credentials \
  --from-literal=AWS_REGION=us-east-1 \
  --from-literal=AWS_ACCESS_KEY_ID=NEW_KEY \
  --from-literal=AWS_SECRET_ACCESS_KEY=NEW_SECRET \
  --from-literal=AWS_S3_BUCKET_NAME=your-bucket \
  -n image-uploader

# Restart deployment
kubectl rollout restart deployment/image-uploader -n image-uploader
```

#### Issue: CORS errors in browser
**Error:** `Access to fetch blocked by CORS policy`

**Solution:**
```bash
# Update S3 bucket CORS configuration
aws s3api put-bucket-cors \
  --bucket your-bucket-name \
  --cors-configuration file://s3-cors.json
```

### 3. Jenkins Pipeline Issues

#### Issue: Jenkins cannot connect to Docker
**Error:** `Cannot connect to Docker daemon`

**Solution:**
```bash
# Add jenkins user to docker group
sudo usermod -aG docker jenkins

# Restart Jenkins
sudo systemctl restart jenkins

# Verify
sudo -u jenkins docker ps
```

#### Issue: Jenkins cannot connect to K8s cluster
**Error:** `Unable to connect to the server`

**Solution:**
```bash
# Copy kubeconfig to Jenkins
sudo mkdir -p /var/lib/jenkins/.kube
sudo cp ~/.kube/config /var/lib/jenkins/.kube/config
sudo chown -R jenkins:jenkins /var/lib/jenkins/.kube

# Or add credentials in Jenkins:
# Manage Jenkins → Credentials → Add → Secret file
# Upload ~/.kube/config
```

#### Issue: Pipeline fails at build stage
**Error:** Various build errors

**Solutions:**
```bash
# Check Jenkins logs
sudo tail -f /var/log/jenkins/jenkins.log

# Test Docker build locally
docker build -t test:latest .

# Check Jenkinsfile syntax
# Use Jenkins Pipeline Syntax validator

# Increase Jenkins memory (if out of memory)
sudo nano /etc/default/jenkins
# Add: JAVA_ARGS="-Xmx2048m"
sudo systemctl restart jenkins
```

### 4. Kubernetes Networking Issues

#### Issue: Cannot access application via NodePort
**Solutions:**
```bash
# 1. Verify service is running
kubectl get svc -n image-uploader

# 2. Check security group rules on EC2
# Ensure port 30080 is open

# 3. Test from inside cluster
kubectl run -it --rm test --image=busybox --restart=Never -- sh
wget -O- http://image-uploader-service.image-uploader.svc.cluster.local

# 4. Check pod is running
kubectl get pods -n image-uploader

# 5. Port forward for testing
kubectl port-forward -n image-uploader svc/image-uploader-service 8080:80
# Access: http://localhost:8080
```

#### Issue: Ingress not working
**Solutions:**
```bash
# 1. Check if ingress controller is installed
kubectl get pods -n ingress-nginx

# 2. Install nginx ingress controller (if missing)
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml

# 3. Verify ingress resource
kubectl describe ingress image-uploader-ingress -n image-uploader

# 4. Check ingress logs
kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx
```

### 5. K3s Cluster Issues

#### Issue: K3s service not running
```bash
sudo systemctl status k3s
```

**Solutions:**
```bash
# Start K3s
sudo systemctl start k3s

# Enable on boot
sudo systemctl enable k3s

# Check logs
sudo journalctl -u k3s -f

# If corrupted, reinstall
/usr/local/bin/k3s-uninstall.sh
curl -sfL https://get.k3s.io | sh -
```

#### Issue: kubectl not working
**Error:** `The connection to the server localhost:8080 was refused`

**Solution:**
```bash
# Set KUBECONFIG
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

# Or copy to user directory
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $USER:$USER ~/.kube/config

# Add to bashrc
echo 'export KUBECONFIG=~/.kube/config' >> ~/.bashrc
source ~/.bashrc
```

### 6. Performance Issues

#### Issue: Application is slow
**Diagnostics:**
```bash
# Check pod resource usage
kubectl top pods -n image-uploader

# Check node resources
kubectl top nodes

# View detailed pod metrics
kubectl describe pod <pod-name> -n image-uploader
```

**Solutions:**
```bash
# 1. Scale up replicas
kubectl scale deployment/image-uploader --replicas=3 -n image-uploader

# 2. Increase resource limits
kubectl edit deployment image-uploader -n image-uploader
# Update resources.limits and resources.requests

# 3. Add horizontal pod autoscaler
kubectl autoscale deployment image-uploader \
  --min=2 --max=10 --cpu-percent=70 \
  -n image-uploader
```

### 7. Storage Issues

#### Issue: Persistent volume issues
**Solutions:**
```bash
# Check PVs and PVCs
kubectl get pv
kubectl get pvc -n image-uploader

# Delete and recreate PVC
kubectl delete pvc <pvc-name> -n image-uploader
kubectl apply -f k8s/persistent-volume.yaml
```

### 8. SSL/TLS Issues

#### Issue: HTTPS not working
**Solutions:**
```bash
# 1. Install cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

# 2. Create ClusterIssuer
kubectl apply -f k8s/04-cert-manager-issuer.yaml

# 3. Update ingress with TLS
# Edit k8s/03-ingress.yaml to add TLS section

# 4. Check certificate
kubectl get certificate -n image-uploader
kubectl describe certificate -n image-uploader
```

### 9. Deployment Rollout Issues

#### Issue: Deployment rollout stuck
```bash
kubectl rollout status deployment/image-uploader -n image-uploader
```

**Solutions:**
```bash
# 1. Check deployment events
kubectl describe deployment image-uploader -n image-uploader

# 2. Check pod events
kubectl get events -n image-uploader --sort-by='.lastTimestamp'

# 3. Rollback if needed
kubectl rollout undo deployment/image-uploader -n image-uploader

# 4. Force delete stuck pods
kubectl delete pod <pod-name> -n image-uploader --force --grace-period=0
```

### 10. Database/State Issues

#### Issue: Images not persisting
**This app uses S3, but if you add a database:**

**Solutions:**
```bash
# Verify S3 connectivity
kubectl exec -it <pod-name> -n image-uploader -- sh
# Inside pod:
env | grep AWS
curl -I https://s3.amazonaws.com

# Test S3 upload
aws s3 cp test.txt s3://your-bucket/test.txt
```

## Diagnostic Commands Cheat Sheet

```bash
# Quick health check
kubectl get all -n image-uploader
kubectl describe deployment image-uploader -n image-uploader
kubectl logs -f deployment/image-uploader -n image-uploader

# Check resource usage
kubectl top pods -n image-uploader
kubectl top nodes

# Network debugging
kubectl run -it --rm debug --image=nicolaka/netshoot --restart=Never -- bash

# DNS testing
nslookup image-uploader-service.image-uploader.svc.cluster.local

# Full cluster status
kubectl cluster-info
kubectl get nodes -o wide
kubectl get pods -A

# Check all events
kubectl get events -A --sort-by='.lastTimestamp'
```

## Emergency Procedures

### Complete Cluster Reset
```bash
# WARNING: This deletes everything!

# Stop K3s
sudo systemctl stop k3s

# Uninstall K3s
/usr/local/bin/k3s-uninstall.sh

# Reinstall K3s
curl -sfL https://get.k3s.io | sh -

# Setup kubeconfig
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $USER:$USER ~/.kube/config

# Redeploy application
kubectl apply -f k8s/
```

### Application Quick Restart
```bash
# Restart all pods
kubectl rollout restart deployment/image-uploader -n image-uploader

# Delete and recreate namespace
kubectl delete namespace image-uploader
kubectl apply -f k8s/
```

## Getting Help

### Collect Diagnostic Information
```bash
# Create diagnostic report
kubectl get all -n image-uploader > diagnostic-report.txt
kubectl describe deployment image-uploader -n image-uploader >> diagnostic-report.txt
kubectl logs deployment/image-uploader -n image-uploader --tail=100 >> diagnostic-report.txt
kubectl get events -n image-uploader --sort-by='.lastTimestamp' >> diagnostic-report.txt

# System information
uname -a >> diagnostic-report.txt
docker --version >> diagnostic-report.txt
kubectl version >> diagnostic-report.txt
```

### Useful Resources
- Kubernetes Documentation: https://kubernetes.io/docs/
- K3s Documentation: https://docs.k3s.io/
- Docker Documentation: https://docs.docker.com/
- AWS S3 Documentation: https://docs.aws.amazon.com/s3/
- Jenkins Documentation: https://www.jenkins.io/doc/
