# Complete CI/CD Pipeline Setup Guide
# Next.js Image Uploader with AWS Integration

This guide provides step-by-step instructions for setting up a complete CI/CD pipeline for the Next.js Image Uploader application with AWS S3 integration, Docker containerization, Kubernetes orchestration, and Jenkins automation.

## 🏗️ Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Developer     │───▶│    Jenkins      │───▶│   Kubernetes    │
│   Commits Code  │    │   CI/CD Server  │    │    Cluster      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                              │                        │
                              ▼                        ▼
                       ┌─────────────────┐    ┌─────────────────┐
                       │   Docker Hub    │    │   Next.js App   │
                       │   Registry      │    │   (Pods)        │
                       └─────────────────┘    └─────────────────┘
                                                       │
                                                       ▼
                                              ┌─────────────────┐
                                              │    AWS S3       │
                                              │ Image Storage   │
                                              └─────────────────┘
```

## 📋 Prerequisites

- AWS Account with appropriate permissions
- Domain name (optional, for production)
- Basic knowledge of Linux, Docker, and Kubernetes
- Git repository for your code

## 🚀 Quick Start (Estimated Time: 45 minutes)

### Phase 1: AWS Resources Setup (10 minutes)

1. **Launch EC2 Instances**
   ```bash
   # Launch 3 EC2 instances (t3.micro for free tier):
   # - 1 Master Node (Kubernetes control plane)
   # - 1 Worker Node (Kubernetes worker)
   # - 1 Jenkins Server (CI/CD)
   
   # Use Ubuntu 20.04 LTS AMI
   # Configure Security Groups:
   # - SSH (22): Your IP
   # - HTTP (80): 0.0.0.0/0
   # - HTTPS (443): 0.0.0.0/0
   # - Jenkins (8080): Your IP
   # - Kubernetes API (6443): Internal IPs
   # - Kubelet (10250): Internal IPs
   ```

2. **Setup S3 Bucket**
   ```bash
   # SSH into any EC2 instance and run:
   wget https://raw.githubusercontent.com/your-repo/image-uploader/main/scripts/setup-s3.sh
   chmod +x setup-s3.sh
   ./setup-s3.sh
   
   # Save the output credentials - you'll need them later!
   ```

### Phase 2: Kubernetes Cluster Setup (15 minutes)

3. **Setup Master Node**
   ```bash
   # SSH into your master node EC2 instance
   wget https://raw.githubusercontent.com/your-repo/image-uploader/main/scripts/setup-k8s-master.sh
   chmod +x setup-k8s-master.sh
   ./setup-k8s-master.sh
   
   # Save the join command from the output!
   ```

4. **Setup Worker Node**
   ```bash
   # SSH into your worker node EC2 instance
   wget https://raw.githubusercontent.com/your-repo/image-uploader/main/scripts/setup-k8s-worker.sh
   chmod +x setup-k8s-worker.sh
   
   # Use the join command from step 3
   ./setup-k8s-worker.sh "kubeadm join 10.0.1.100:6443 --token abc123... --discovery-token-ca-cert-hash sha256:..."
   ```

5. **Verify Cluster**
   ```bash
   # On master node:
   kubectl get nodes
   # Should show both master and worker nodes as "Ready"
   ```

### Phase 3: Jenkins Setup (10 minutes)

6. **Install Jenkins**
   ```bash
   # SSH into your Jenkins EC2 instance
   wget https://raw.githubusercontent.com/your-repo/image-uploader/main/scripts/setup-jenkins.sh
   chmod +x setup-jenkins.sh
   ./setup-jenkins.sh
   
   # Note the initial admin password from the output
   ```

7. **Configure Jenkins**
   - Access Jenkins at `http://YOUR_JENKINS_IP:8080`
   - Use the admin password from step 6
   - Install suggested plugins
   - Create admin user
   - Install additional plugins:
     - Docker Pipeline
     - Kubernetes
     - NodeJS Plugin

### Phase 4: Application Deployment (10 minutes)

8. **Configure Kubernetes Secrets**
   ```bash
   # On master node, encode your AWS credentials:
   echo -n 'YOUR_ACCESS_KEY_ID' | base64
   echo -n 'YOUR_SECRET_ACCESS_KEY' | base64
   
   # Update k8s/00-namespace-secrets.yaml with the encoded values
   # Update AWS_S3_BUCKET_NAME with your bucket name from step 2
   ```

9. **Deploy Application**
   ```bash
   # Clone your repository on master node
   git clone https://github.com/your-username/image-uploader.git
   cd image-uploader
   
   # Apply Kubernetes manifests
   kubectl apply -f k8s/
   
   # Check deployment status
   kubectl get pods -n image-uploader
   kubectl get services -n image-uploader
   ```

## 📝 Detailed Setup Instructions

### AWS S3 Configuration

The S3 setup script creates:
- S3 bucket with public read access for images
- CORS configuration for web uploads
- Lifecycle policy for cost optimization
- IAM user with minimal required permissions
- Access keys for application use

**Important**: Store the AWS credentials securely and never commit them to version control.

### Kubernetes Cluster Details

**Master Node Components:**
- kubeadm, kubelet, kubectl
- Flannel CNI for pod networking
- NGINX Ingress Controller
- Metrics Server for horizontal pod autoscaling

**Security Configuration:**
- Network policies for pod-to-pod communication
- RBAC for service accounts
- Secrets management for sensitive data
- Resource limits and quotas

### Jenkins Pipeline Stages

1. **Checkout**: Clone source code
2. **Install Dependencies**: pnpm install
3. **Lint & Type Check**: ESLint and TypeScript validation
4. **Build**: Next.js production build
5. **Test**: Run test suite (add your tests)
6. **Docker Build**: Create container image
7. **Security Scan**: Container vulnerability scanning
8. **Push Registry**: Upload to Docker Hub
9. **Deploy K8s**: Update Kubernetes deployment
10. **Smoke Tests**: Verify deployment health

## 🔧 Configuration Files

### Environment Variables (.env.local)

```bash
# AWS Configuration
AWS_ACCESS_KEY_ID=your_access_key_id
AWS_SECRET_ACCESS_KEY=your_secret_access_key
AWS_REGION=us-east-1
AWS_S3_BUCKET_NAME=your-bucket-name

# Application Configuration
NODE_ENV=production
STORAGE_TYPE=s3
NEXT_TELEMETRY_DISABLED=1
```

### Jenkins Credentials Setup

In Jenkins, add these credentials (Manage Jenkins → Credentials):

1. **dockerhub-credentials**: Username/Password for Docker Hub
2. **kubeconfig-file**: Secret file with Kubernetes config from master node
3. **aws-credentials**: Username/Password for AWS (optional, for additional AWS operations)

### Kubernetes Secrets Update

Update `k8s/00-namespace-secrets.yaml`:

```yaml
data:
  # Base64 encoded values
  access-key-id: <base64_encoded_access_key>
  secret-access-key: <base64_encoded_secret_key>
```

## 🧪 Testing the Complete Workflow

### 1. Local Development Test
```bash
# Clone and setup locally
git clone https://github.com/your-username/image-uploader.git
cd image-uploader
cp .env.example .env.local
# Update .env.local with your AWS credentials

pnpm install
pnpm dev
# Test at http://localhost:3000
```

### 2. Docker Build Test
```bash
docker build -t image-uploader:test .
docker run -p 3000:3000 -e AWS_ACCESS_KEY_ID=xxx -e AWS_SECRET_ACCESS_KEY=xxx image-uploader:test
```

### 3. Kubernetes Deployment Test
```bash
# Check pod status
kubectl get pods -n image-uploader

# Check logs
kubectl logs -f deployment/image-uploader-app -n image-uploader

# Test health endpoint
kubectl port-forward service/image-uploader-service 8080:80 -n image-uploader
curl http://localhost:8080/api/health
```

### 4. CI/CD Pipeline Test
1. Make a code change
2. Commit and push to main branch
3. Check Jenkins pipeline execution
4. Verify automatic deployment to Kubernetes
5. Test the live application

## 🔍 Monitoring and Troubleshooting

### Common Issues

**Pod Stuck in Pending:**
```bash
kubectl describe pod <pod-name> -n image-uploader
# Check resource constraints and node capacity
```

**Image Pull Errors:**
```bash
# Verify Docker Hub credentials
kubectl get events -n image-uploader --sort-by=.metadata.creationTimestamp
```

**S3 Upload Failures:**
```bash
# Check AWS credentials and permissions
kubectl logs deployment/image-uploader-app -n image-uploader | grep -i "s3\|aws"
```

**Jenkins Build Failures:**
- Check Jenkins logs in the web interface
- Verify Docker daemon is running
- Ensure kubectl has access to cluster

### Health Checks

**Application Health:**
```bash
# Via kubectl
kubectl get pods -n image-uploader
kubectl describe deployment image-uploader-app -n image-uploader

# Via API
curl http://your-domain.com/api/health
```

**Cluster Health:**
```bash
kubectl get nodes
kubectl get pods --all-namespaces
kubectl top nodes  # Requires metrics server
```

### Log Monitoring

**Application Logs:**
```bash
kubectl logs -f deployment/image-uploader-app -n image-uploader
```

**Ingress Logs:**
```bash
kubectl logs -f -n ingress-nginx deployment/ingress-nginx-controller
```

**Jenkins Logs:**
```bash
# On Jenkins server
sudo journalctl -u jenkins -f
```

## 🔒 Security Best Practices

### AWS Security
- Use IAM roles instead of access keys when possible
- Enable CloudTrail for audit logging
- Set up S3 bucket notifications for monitoring
- Implement least-privilege access policies

### Kubernetes Security
- Enable RBAC and network policies
- Use resource quotas and limits
- Regularly update cluster components
- Implement pod security policies

### Jenkins Security
- Enable HTTPS/SSL
- Use credential binding plugins
- Implement job-level permissions
- Regular security updates

## 📈 Scaling and Optimization

### Horizontal Pod Autoscaling
The HPA is configured to scale based on CPU and memory usage:
- Min replicas: 2
- Max replicas: 5
- CPU target: 70%
- Memory target: 80%

### Performance Optimization
- Next.js static optimization enabled
- Docker multi-stage builds for smaller images
- S3 lifecycle policies for cost optimization
- CDN integration (recommended for production)

## 🚨 Disaster Recovery

### Backup Strategy
- Kubernetes cluster configuration backups
- Jenkins job configurations and credentials
- S3 bucket versioning enabled
- Database backups (if using database)

### Rollback Procedures
```bash
# Rollback Kubernetes deployment
kubectl rollout undo deployment/image-uploader-app -n image-uploader

# Rollback to specific revision
kubectl rollout undo deployment/image-uploader-app --to-revision=2 -n image-uploader

# Jenkins rollback pipeline
# Use the rollback job in Jenkins with specific Docker tag
```

## 🎯 Production Checklist

- [ ] Domain name configured with DNS
- [ ] SSL/TLS certificates installed
- [ ] Monitoring and alerting setup
- [ ] Backup procedures tested
- [ ] Security scanning implemented
- [ ] Load testing completed
- [ ] Documentation updated
- [ ] Team training completed

## 📚 Additional Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Jenkins Pipeline Documentation](https://www.jenkins.io/doc/book/pipeline/)
- [AWS S3 Best Practices](https://docs.aws.amazon.com/s3/latest/userguide/security-best-practices.html)
- [Next.js Deployment Guide](https://nextjs.org/docs/deployment)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)

## 🆘 Support

If you encounter issues:
1. Check the troubleshooting section above
2. Review logs for error messages
3. Verify all prerequisites are met
4. Check AWS service status
5. Consult the official documentation

---

**Total estimated setup time**: 45-60 minutes
**Skill level**: Intermediate
**Cost**: Free tier eligible (with limitations)

This guide provides a production-ready CI/CD pipeline for your Next.js image uploader application. Customize the configuration based on your specific requirements and scale as needed.