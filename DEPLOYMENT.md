# CI/CD Pipeline Deployment Guide

## Complete Deployment of Dockerized Image Uploader on Kubernetes using Jenkins

This guide will walk you through deploying the image-uploader application on AWS EC2 using K3s (lightweight Kubernetes) and Jenkins for CI/CD.

---

## Architecture Overview

```
GitHub Repository
       ↓
   Jenkins Pipeline
       ↓
   Docker Image Build
       ↓
   Docker Hub Registry
       ↓
   K3s Kubernetes Cluster (on EC2)
       ↓
   Application Pods
       ↓
   AWS S3 (Image Storage)
```

---

## Prerequisites

- AWS Account
- GitHub Account
- Docker Hub Account
- Domain name (optional, for production)
- SSH client

---

## Part 1: AWS Setup

### 1.1 Create S3 Bucket for Image Storage

```bash
# Login to AWS Console
# Navigate to S3 service
# Click "Create bucket"
```

**Bucket Configuration:**
- Bucket name: `image-uploader-bucket-{your-unique-id}`
- Region: `us-east-1` (or your preferred region)
- Block Public Access: Uncheck (or configure CORS for your domain)
- Versioning: Enabled (recommended)
- Encryption: Enabled (AES-256)

**CORS Configuration (if public access):**
```json
[
    {
        "AllowedHeaders": ["*"],
        "AllowedMethods": ["GET", "PUT", "POST", "DELETE"],
        "AllowedOrigins": ["*"],
        "ExposeHeaders": ["ETag"]
    }
]
```

**Bucket Policy (for public read):**
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::image-uploader-bucket-{your-unique-id}/images/*"
        }
    ]
}
```

### 1.2 Create IAM User for S3 Access

```bash
# Navigate to IAM → Users → Add User
```

**User Configuration:**
- Username: `image-uploader-s3-user`
- Access type: Programmatic access

**Attach Policy:**
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:DeleteObject",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::image-uploader-bucket-{your-unique-id}",
                "arn:aws:s3:::image-uploader-bucket-{your-unique-id}/*"
            ]
        }
    ]
}
```

**Save the credentials:**
- Access Key ID
- Secret Access Key

### 1.3 Launch EC2 Instance

**Instance Configuration:**
- AMI: Ubuntu Server 22.04 LTS
- Instance Type: `t3.medium` (2 vCPU, 4 GB RAM)
- Storage: 30 GB GP3
- Security Group Rules:
  - SSH (22) - Your IP
  - HTTP (80) - 0.0.0.0/0
  - HTTPS (443) - 0.0.0.0/0
  - Custom TCP (8080) - Your IP (Jenkins)
  - Custom TCP (30080) - 0.0.0.0/0 (K3s NodePort)
  - Custom TCP (6443) - Your IP (K3s API)

**Launch Steps:**
```bash
# 1. Navigate to EC2 → Launch Instance
# 2. Choose Ubuntu 22.04 LTS
# 3. Select t3.medium
# 4. Configure security group as above
# 5. Create/select key pair
# 6. Launch instance
```

---

## Part 2: Server Setup

### 2.1 Connect to EC2 Instance

```bash
# Download your key pair (.pem file)
chmod 400 your-key.pem
ssh -i your-key.pem ubuntu@<EC2-PUBLIC-IP>
```

### 2.2 Initial System Setup

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install essential tools
sudo apt install -y curl wget git vim unzip

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker ubuntu
sudo systemctl enable docker
sudo systemctl start docker

# Logout and login again to apply docker group
exit
# SSH back in
```

### 2.3 Install K3s (Lightweight Kubernetes)

```bash
# Install K3s
curl -sfL https://get.k3s.io | sh -

# Verify installation
sudo k3s kubectl get nodes

# Setup kubectl for current user
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown ubuntu:ubuntu ~/.kube/config
export KUBECONFIG=~/.kube/config
echo 'export KUBECONFIG=~/.kube/config' >> ~/.bashrc

# Create kubectl alias
echo 'alias kubectl="k3s kubectl"' >> ~/.bashrc
source ~/.bashrc

# Verify
kubectl get nodes
kubectl get pods -A
```

### 2.4 Install Jenkins

```bash
# Install Java
sudo apt install -y openjdk-17-jre openjdk-17-jdk

# Add Jenkins repository
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee \
  /usr/share/keyrings/jenkins-keyring.asc > /dev/null

echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null

# Install Jenkins
sudo apt update
sudo apt install -y jenkins

# Start Jenkins
sudo systemctl enable jenkins
sudo systemctl start jenkins
sudo systemctl status jenkins

# Get initial admin password
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

**Access Jenkins:**
- URL: `http://<EC2-PUBLIC-IP>:8080`
- Use the initial admin password from above

### 2.5 Configure Jenkins

**Install Required Plugins:**
1. Navigate to: Manage Jenkins → Plugins
2. Install these plugins:
   - Docker Pipeline
   - Kubernetes CLI
   - Git
   - Pipeline
   - Credentials Binding

**Add Docker to Jenkins:**
```bash
# Add jenkins user to docker group
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins
```

**Configure Credentials in Jenkins:**

1. **Docker Hub Credentials:**
   - Go to: Manage Jenkins → Credentials → System → Global credentials
   - Click "Add Credentials"
   - Kind: Username with password
   - Username: Your Docker Hub username
   - Password: Your Docker Hub password
   - ID: `dockerhub-credentials`

2. **Kubeconfig:**
   - Kind: Secret file
   - File: Upload `~/.kube/config`
   - ID: `kubeconfig`

3. **GitHub Credentials (if private repo):**
   - Kind: Username with password or SSH key
   - ID: `github-credentials`

---

## Part 3: Application Deployment

### 3.1 Update Kubernetes Secrets

```bash
# Edit the secrets file
cd ~/
git clone https://github.com/your-username/image-uploader.git
cd image-uploader

# Update k8s/00-namespace-secrets.yaml with your AWS credentials
nano k8s/00-namespace-secrets.yaml
```

Replace these values:
- `AWS_ACCESS_KEY_ID`: Your IAM user access key
- `AWS_SECRET_ACCESS_KEY`: Your IAM user secret key
- `AWS_S3_BUCKET_NAME`: Your S3 bucket name
- `AWS_REGION`: Your AWS region (e.g., us-east-1)

### 3.2 Update Kubernetes Deployment

```bash
# Edit deployment.yaml
nano k8s/01-deployment.yaml
```

Replace `your-dockerhub-username/image-uploader:latest` with your actual Docker Hub username.

### 3.3 Create Jenkins Pipeline

1. **Create New Pipeline Job:**
   - Jenkins Dashboard → New Item
   - Name: `image-uploader-pipeline`
   - Type: Pipeline
   - Click OK

2. **Configure Pipeline:**
   - Scroll to Pipeline section
   - Definition: Pipeline script from SCM
   - SCM: Git
   - Repository URL: Your GitHub repo URL
   - Credentials: Select your GitHub credentials (if private)
   - Branch: `*/main` or `*/master`
   - Script Path: `Jenkinsfile`
   - Save

3. **Update Jenkinsfile:**
   - Edit line with `your-dockerhub-username`
   - Commit and push to GitHub

### 3.4 Deploy Application

**Option 1: Using Jenkins Pipeline**
```bash
# Trigger build from Jenkins UI
# Jenkins → image-uploader-pipeline → Build Now
```

**Option 2: Manual Deployment**
```bash
# Build Docker image locally
docker build -t your-dockerhub-username/image-uploader:latest .

# Push to Docker Hub
docker login
docker push your-dockerhub-username/image-uploader:latest

# Deploy to Kubernetes
kubectl apply -f k8s/00-namespace-secrets.yaml
kubectl apply -f k8s/01-deployment.yaml
kubectl apply -f k8s/02-service.yaml
kubectl apply -f k8s/03-ingress.yaml

# Verify deployment
kubectl get pods -n image-uploader
kubectl get services -n image-uploader
```

---

## Part 4: Verification and Testing

### 4.1 Check Deployment Status

```bash
# Check pods
kubectl get pods -n image-uploader

# Check services
kubectl get services -n image-uploader

# Check logs
kubectl logs -f deployment/image-uploader -n image-uploader

# Describe pod for issues
kubectl describe pod <pod-name> -n image-uploader
```

### 4.2 Access Application

```bash
# Get NodePort
kubectl get svc -n image-uploader

# Access application
# URL: http://<EC2-PUBLIC-IP>:30080
```

### 4.3 Test Image Upload

1. Open browser: `http://<EC2-PUBLIC-IP>:30080`
2. Upload an image
3. Verify image appears in grid
4. Check S3 bucket for uploaded image

---

## Part 5: Monitoring and Maintenance

### 5.1 View Application Logs

```bash
# Real-time logs
kubectl logs -f deployment/image-uploader -n image-uploader

# Last 100 lines
kubectl logs --tail=100 deployment/image-uploader -n image-uploader
```

### 5.2 Scale Application

```bash
# Scale to 3 replicas
kubectl scale deployment/image-uploader --replicas=3 -n image-uploader

# Verify
kubectl get pods -n image-uploader
```

### 5.3 Update Application

```bash
# Method 1: Through Jenkins
# Push code changes to GitHub
# Jenkins will automatically build and deploy

# Method 2: Manual update
docker build -t your-dockerhub-username/image-uploader:v2 .
docker push your-dockerhub-username/image-uploader:v2
kubectl set image deployment/image-uploader \
  image-uploader=your-dockerhub-username/image-uploader:v2 \
  -n image-uploader
```

### 5.4 Rollback Deployment

```bash
# View rollout history
kubectl rollout history deployment/image-uploader -n image-uploader

# Rollback to previous version
kubectl rollout undo deployment/image-uploader -n image-uploader

# Rollback to specific revision
kubectl rollout undo deployment/image-uploader --to-revision=2 -n image-uploader
```

---

## Part 6: Troubleshooting

### Common Issues

**1. Pods Not Starting**
```bash
kubectl describe pod <pod-name> -n image-uploader
kubectl logs <pod-name> -n image-uploader
```

**2. Image Pull Errors**
```bash
# Verify Docker Hub credentials
docker login
docker pull your-dockerhub-username/image-uploader:latest
```

**3. S3 Connection Issues**
```bash
# Verify AWS credentials in secret
kubectl get secret aws-credentials -n image-uploader -o yaml

# Check pod environment variables
kubectl exec -it <pod-name> -n image-uploader -- env | grep AWS
```

**4. Jenkins Build Failures**
```bash
# Check Jenkins logs
sudo tail -f /var/log/jenkins/jenkins.log

# Verify Docker in Jenkins
docker ps
sudo systemctl status docker
```

---

## Part 7: Cost Optimization

### Estimated Monthly Costs

- **EC2 t3.medium:** ~$30-35/month
- **S3 Storage:** ~$0.023/GB/month
- **Data Transfer:** ~$0.09/GB (first 10TB)
- **Total:** ~$35-40/month (for low traffic)

### Cost-Saving Tips

1. **Use Spot Instances** (save up to 70%)
2. **Enable S3 Lifecycle Policies** (move old images to Glacier)
3. **Use CloudFront CDN** (reduce S3 data transfer costs)
4. **Stop EC2 when not needed** (development environments)
5. **Use Reserved Instances** (for production, save up to 72%)

---

## Part 8: Security Best Practices

### 8.1 Secure Jenkins

```bash
# Enable CSRF protection
# Navigate to: Manage Jenkins → Security → Configure Global Security
# Enable "Prevent Cross Site Request Forgery exploits"

# Install Security plugins:
# - Role-based Authorization Strategy
# - OWASP Markup Formatter
```

### 8.2 Secure Kubernetes

```bash
# Use network policies
# Create separate namespaces for different environments
# Implement RBAC (Role-Based Access Control)
# Use secrets for sensitive data
# Enable audit logging
```

### 8.3 Secure S3

```bash
# Enable versioning
# Enable encryption
# Use bucket policies
# Enable access logging
# Use VPC endpoints (for internal access)
```

---

## Part 9: Production Enhancements

### 9.1 Setup Domain Name

```bash
# 1. Purchase domain from Route 53 or other registrar
# 2. Create A record pointing to EC2 public IP
# 3. Update ingress.yaml with your domain
# 4. Install cert-manager for HTTPS
```

### 9.2 Install Ingress Controller

```bash
# Install Nginx Ingress Controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml

# Verify
kubectl get pods -n ingress-nginx
```

### 9.3 Setup HTTPS with Let's Encrypt

```bash
# Install cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

# Create ClusterIssuer
# See deployment/cert-manager-issuer.yaml
```

---

## Part 10: Next Steps

1. **Setup Monitoring:**
   - Prometheus + Grafana
   - CloudWatch integration

2. **Setup Logging:**
   - ELK Stack (Elasticsearch, Logstash, Kibana)
   - CloudWatch Logs

3. **Setup CI/CD Enhancements:**
   - Automated testing
   - Code quality checks
   - Security scanning

4. **Setup Backup:**
   - Automated S3 backups
   - Database backups (if using)
   - Disaster recovery plan

---

## Quick Reference Commands

```bash
# Kubernetes
kubectl get pods -n image-uploader
kubectl logs -f deployment/image-uploader -n image-uploader
kubectl describe pod <pod-name> -n image-uploader
kubectl delete pod <pod-name> -n image-uploader

# Docker
docker ps
docker images
docker logs <container-id>
docker exec -it <container-id> /bin/sh

# K3s
sudo systemctl status k3s
sudo journalctl -u k3s -f

# Jenkins
sudo systemctl status jenkins
sudo systemctl restart jenkins
sudo tail -f /var/log/jenkins/jenkins.log
```

---

## Support and Resources

- **K3s Documentation:** https://docs.k3s.io/
- **Jenkins Documentation:** https://www.jenkins.io/doc/
- **Kubernetes Documentation:** https://kubernetes.io/docs/
- **AWS Documentation:** https://docs.aws.amazon.com/
- **Docker Documentation:** https://docs.docker.com/

---

## License

MIT License - See LICENSE file for details
