# Quick Reference Guide

## AWS S3 Setup Commands

### Create S3 Bucket (AWS CLI)
```bash
aws s3 mb s3://image-uploader-bucket-$(date +%s) --region us-east-1
```

### Set Bucket CORS
```bash
aws s3api put-bucket-cors --bucket your-bucket-name --cors-configuration file://s3-cors.json
```

### Create IAM User
```bash
aws iam create-user --user-name image-uploader-s3-user
aws iam attach-user-policy --user-name image-uploader-s3-user --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess
aws iam create-access-key --user-name image-uploader-s3-user
```

## EC2 Commands

### Connect to EC2
```bash
ssh -i your-key.pem ubuntu@<EC2-PUBLIC-IP>
```

### Check System Resources
```bash
# CPU and Memory
htop

# Disk space
df -h

# Running processes
ps aux | grep -E 'jenkins|k3s|docker'
```

## K3s Commands

### Cluster Status
```bash
sudo systemctl status k3s
kubectl get nodes
kubectl cluster-info
```

### View All Resources
```bash
kubectl get all -n image-uploader
kubectl get all -A
```

### Port Forwarding (for local testing)
```bash
kubectl port-forward -n image-uploader svc/image-uploader-service 8080:80
```

### Execute Command in Pod
```bash
kubectl exec -it <pod-name> -n image-uploader -- /bin/sh
```

### Get Pod YAML
```bash
kubectl get pod <pod-name> -n image-uploader -o yaml
```

## Docker Commands

### Build and Tag
```bash
docker build -t your-username/image-uploader:v1.0 .
docker tag your-username/image-uploader:v1.0 your-username/image-uploader:latest
```

### Push to Registry
```bash
docker login
docker push your-username/image-uploader:v1.0
docker push your-username/image-uploader:latest
```

### Clean Up
```bash
# Remove unused images
docker image prune -a

# Remove unused containers
docker container prune

# Remove everything unused
docker system prune -a --volumes
```

### Debug Container
```bash
# Run with shell
docker run -it your-username/image-uploader:latest /bin/sh

# View logs
docker logs -f <container-id>

# Inspect container
docker inspect <container-id>
```

## Jenkins Commands

### Service Management
```bash
sudo systemctl status jenkins
sudo systemctl restart jenkins
sudo systemctl stop jenkins
sudo systemctl start jenkins
```

### View Logs
```bash
sudo tail -f /var/log/jenkins/jenkins.log
sudo journalctl -u jenkins -f
```

### Get Initial Password
```bash
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

### Jenkins CLI
```bash
# Download CLI
wget http://localhost:8080/jnlpJars/jenkins-cli.jar

# List jobs
java -jar jenkins-cli.jar -s http://localhost:8080/ list-jobs

# Build job
java -jar jenkins-cli.jar -s http://localhost:8080/ build image-uploader-pipeline
```

## Kubernetes Deployment Commands

### Apply Changes
```bash
# Apply specific file
kubectl apply -f k8s/01-deployment.yaml

# Apply all files in directory
kubectl apply -f k8s/

# Apply with record (for rollout history)
kubectl apply -f k8s/01-deployment.yaml --record
```

### Update Image
```bash
kubectl set image deployment/image-uploader \
  image-uploader=your-username/image-uploader:v2 \
  -n image-uploader
```

### Scale
```bash
# Scale up
kubectl scale deployment/image-uploader --replicas=5 -n image-uploader

# Scale down
kubectl scale deployment/image-uploader --replicas=1 -n image-uploader

# Auto-scale
kubectl autoscale deployment image-uploader \
  --min=2 --max=10 --cpu-percent=80 \
  -n image-uploader
```

### Rollout Management
```bash
# Check rollout status
kubectl rollout status deployment/image-uploader -n image-uploader

# View rollout history
kubectl rollout history deployment/image-uploader -n image-uploader

# Undo rollout
kubectl rollout undo deployment/image-uploader -n image-uploader

# Pause rollout
kubectl rollout pause deployment/image-uploader -n image-uploader

# Resume rollout
kubectl rollout resume deployment/image-uploader -n image-uploader
```

## Troubleshooting Commands

### Pod Issues
```bash
# Get pod details
kubectl describe pod <pod-name> -n image-uploader

# Get events
kubectl get events -n image-uploader --sort-by='.lastTimestamp'

# Get pod logs
kubectl logs <pod-name> -n image-uploader

# Get previous pod logs (if crashed)
kubectl logs <pod-name> -n image-uploader --previous

# Watch pods
kubectl get pods -n image-uploader -w
```

### Network Debugging
```bash
# Test service connectivity
kubectl run -it --rm debug --image=busybox --restart=Never -- sh

# Inside the pod:
wget -O- http://image-uploader-service.image-uploader.svc.cluster.local

# DNS debugging
kubectl run -it --rm debug --image=nicolaka/netshoot --restart=Never -- bash
nslookup image-uploader-service.image-uploader.svc.cluster.local
```

### Resource Usage
```bash
# Pod resource usage
kubectl top pods -n image-uploader

# Node resource usage
kubectl top nodes

# Describe resource limits
kubectl describe deployment image-uploader -n image-uploader
```

## Monitoring Commands

### Watch Real-time Updates
```bash
# Watch pods
watch kubectl get pods -n image-uploader

# Watch deployment
watch kubectl get deployment -n image-uploader
```

### Get Metrics
```bash
# Install metrics server (if not installed)
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Get metrics
kubectl top pods -n image-uploader
kubectl top nodes
```

## Backup and Restore

### Backup
```bash
# Export all resources
kubectl get all -n image-uploader -o yaml > backup.yaml

# Backup secrets
kubectl get secrets -n image-uploader -o yaml > secrets-backup.yaml

# Backup configmaps
kubectl get configmaps -n image-uploader -o yaml > configmaps-backup.yaml
```

### Restore
```bash
kubectl apply -f backup.yaml
```

## Useful One-Liners

```bash
# Get all pods with their images
kubectl get pods -n image-uploader -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.containers[*].image}{"\n"}{end}'

# Get pod IPs
kubectl get pods -n image-uploader -o wide

# Delete all evicted pods
kubectl get pods -n image-uploader | grep Evicted | awk '{print $1}' | xargs kubectl delete pod -n image-uploader

# Get logs from all pods
kubectl logs -n image-uploader -l app=image-uploader --tail=100

# Restart deployment
kubectl rollout restart deployment/image-uploader -n image-uploader
```

## Environment Variables Check

```bash
# Check env vars in running pod
kubectl exec <pod-name> -n image-uploader -- env

# Check specific env var
kubectl exec <pod-name> -n image-uploader -- env | grep AWS
```

## Performance Testing

```bash
# Install Apache Bench
sudo apt install apache2-utils

# Test upload endpoint
ab -n 100 -c 10 http://<EC2-IP>:30080/api/upload

# Test image list endpoint
ab -n 1000 -c 100 http://<EC2-IP>:30080/api/images
```

## SSL/TLS Setup (Optional)

```bash
# Install cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

# Verify installation
kubectl get pods -n cert-manager
```
