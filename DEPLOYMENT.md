# CI/CD Pipeline Deployment Guide

## Complete Guide to Deploy Next.js Image Uploader on AWS EKS using Jenkins

This guide provides step-by-step instructions to set up a complete CI/CD pipeline for deploying the Next.js Image Uploader application on AWS EKS using Jenkins, all within AWS free tier limits.

## 🏗️ Architecture Overview

```
GitHub → Jenkins → Docker Hub → AWS EKS → LoadBalancer → Your App
```

- **Source Control**: GitHub repository
- **CI/CD**: Jenkins on EC2 (t2.micro - free tier)
- **Container Registry**: Docker Hub (free)
- **Orchestration**: AWS EKS (managed Kubernetes)
- **Compute**: EC2 t3.small nodes (minimal cost)
- **Storage**: EBS volumes for persistent storage

## 📋 Prerequisites

- AWS Account with free tier access
- GitHub account
- Docker Hub account
- Domain name (optional, for ingress)

## 🚀 Step-by-Step Setup

### Step 1: AWS Infrastructure Setup

#### 1.1 Launch EC2 Instance for Jenkins

1. **Launch EC2 Instance**:
   - AMI: Ubuntu Server 22.04 LTS
   - Instance Type: t2.micro (free tier)
   - Security Group: Allow ports 22 (SSH), 8080 (Jenkins), 80/443 (HTTP/HTTPS)
   - Key Pair: Create/select your key pair

2. **Connect to Instance**:
   ```bash
   ssh -i your-key.pem ubuntu@your-ec2-ip
   ```

3. **Install Jenkins**:
   ```bash
   # Copy and run the setup script
   curl -O https://raw.githubusercontent.com/your-repo/image-uploader/main/scripts/setup-jenkins.sh
   chmod +x setup-jenkins.sh
   ./setup-jenkins.sh
   ```

#### 1.2 Setup EKS Cluster

1. **Configure AWS CLI**:
   ```bash
   aws configure
   # Enter your AWS Access Key, Secret Key, Region (us-east-1), and format (json)
   ```

2. **Create EKS Cluster**:
   ```bash
   # Copy and run the EKS setup script
   curl -O https://raw.githubusercontent.com/your-repo/image-uploader/main/scripts/setup-eks.sh
   chmod +x setup-eks.sh
   ./setup-eks.sh
   ```

### Step 2: Jenkins Configuration

#### 2.1 Initial Jenkins Setup

1. **Access Jenkins**: `http://your-ec2-ip:8080`
2. **Get initial password**: 
   ```bash
   sudo cat /var/lib/jenkins/secrets/initialAdminPassword
   ```
3. **Install suggested plugins** + these additional plugins:
   - Pipeline
   - Docker Pipeline
   - Kubernetes CLI
   - AWS Steps
   - Blue Ocean (optional)

#### 2.2 Configure Credentials

1. **Docker Hub Credentials**:
   - Manage Jenkins → Credentials → System → Global credentials
   - Add → Username with password
   - ID: `docker-hub-credentials`
   - Username: Your Docker Hub username
   - Password: Your Docker Hub password/token

2. **AWS Credentials**:
   - Add → Secret text
   - ID: `aws-access-key-id`
   - Secret: Your AWS Access Key ID
   
   - Add → Secret text
   - ID: `aws-secret-access-key`
   - Secret: Your AWS Secret Access Key

3. **Kubeconfig**:
   ```bash
   # On your Jenkins server, get kubeconfig
   cat ~/.kube/config
   ```
   - Add → Secret file
   - ID: `kubeconfig-credentials`
   - File: Upload your kubeconfig file

### Step 3: Project Setup

#### 3.1 Update Configuration Files

1. **Update Jenkinsfile**:
   ```groovy
   environment {
       DOCKER_REGISTRY = 'your-dockerhub-username'  // Change this
       AWS_REGION = 'us-east-1'
       EKS_CLUSTER_NAME = 'image-uploader-cluster'
   }
   ```

2. **Update Kubernetes Deployment**:
   - Edit `k8s/deployment.yaml` if needed
   - Ensure image name matches your Docker Hub repository

#### 3.2 Create Jenkins Pipeline

1. **New Item** → **Pipeline** → Name: `image-uploader-pipeline`
2. **Pipeline Configuration**:
   - Definition: Pipeline script from SCM
   - SCM: Git
   - Repository URL: Your GitHub repository URL
   - Branch: `*/main`
   - Script Path: `Jenkinsfile`

### Step 4: Setup GitHub Webhook (Optional)

1. **GitHub Repository Settings** → **Webhooks** → **Add webhook**
2. **Payload URL**: `http://your-jenkins-ip:8080/github-webhook/`
3. **Content type**: `application/json`
4. **Events**: Just the push event

### Step 5: Deploy Application

#### 5.1 Manual Deployment

1. **Run Jenkins Pipeline**:
   - Go to your pipeline
   - Click "Build Now"
   - Monitor the build progress

2. **Alternative: Direct Deployment**:
   ```bash
   # Clone repository
   git clone https://github.com/your-username/image-uploader.git
   cd image-uploader
   
   # Make scripts executable (Linux/Mac)
   chmod +x scripts/*.sh
   
   # Deploy
   ./scripts/deploy.sh deploy latest
   ```

#### 5.2 Verify Deployment

1. **Check pod status**:
   ```bash
   kubectl get pods -n image-uploader
   ```

2. **Get service URL**:
   ```bash
   kubectl get service image-uploader-service -n image-uploader
   ```

3. **Access application**:
   ```bash
   # Get LoadBalancer URL
   kubectl get service image-uploader-service -n image-uploader -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
   ```

## 🔧 Useful Commands

### Jenkins Management
```bash
# Restart Jenkins
sudo systemctl restart jenkins

# View Jenkins logs
sudo journalctl -u jenkins -f
```

### Kubernetes Management
```bash
# View all resources
kubectl get all -n image-uploader

# View logs
kubectl logs -f deployment/image-uploader-deployment -n image-uploader

# Scale deployment
kubectl scale deployment image-uploader-deployment --replicas=3 -n image-uploader

# Delete deployment
kubectl delete namespace image-uploader
```

### Docker Management
```bash
# Build image locally
docker build -t image-uploader:latest .

# Run locally
docker run -p 3000:3000 image-uploader:latest
```

## 🎯 Cost Optimization (Free Tier)

1. **EC2 Instance**: Use t2.micro for Jenkins (free tier)
2. **EKS Control Plane**: $0.10/hour (not free, but minimal)
3. **Worker Nodes**: Use t3.small, minimum 1 node
4. **Storage**: Use gp2 volumes (free tier eligible)
5. **Load Balancer**: Application Load Balancer (cost applies)

**Estimated Monthly Cost**: $15-25 (mainly EKS control plane + small worker node)

## 🔐 Security Best Practices

1. **EC2 Security Groups**: Restrict access to necessary ports only
2. **IAM Roles**: Use least-privilege principle
3. **Secrets**: Store sensitive data in Jenkins credentials, not in code
4. **Container Scanning**: Pipeline includes Trivy security scanning
5. **Network Policies**: Consider implementing Kubernetes network policies

## 🐛 Troubleshooting

### Common Issues

1. **Pipeline Fails at Docker Build**:
   - Check if Docker daemon is running: `sudo systemctl status docker`
   - Ensure jenkins user is in docker group: `sudo usermod -aG docker jenkins`

2. **Kubernetes Deployment Fails**:
   - Check kubeconfig: `kubectl cluster-info`
   - Verify EKS cluster is running: `aws eks describe-cluster --name image-uploader-cluster`

3. **LoadBalancer Pending**:
   - AWS LoadBalancer Controller might not be installed
   - Check AWS VPC subnets have proper tags

4. **Image Pull Errors**:
   - Verify Docker Hub credentials in Jenkins
   - Ensure image exists and is public (or registry is authenticated)

### Logs and Debugging

```bash
# Jenkins logs
sudo tail -f /var/log/jenkins/jenkins.log

# Kubernetes events
kubectl get events -n image-uploader --sort-by='.lastTimestamp'

# Pod logs
kubectl logs -f <pod-name> -n image-uploader
```

## 🚀 Next Steps

1. **Domain Setup**: Configure Route 53 for custom domain
2. **SSL/TLS**: Set up cert-manager for automatic SSL certificates
3. **Monitoring**: Add Prometheus and Grafana for monitoring
4. **Scaling**: Configure Horizontal Pod Autoscaler
5. **Database**: Add RDS PostgreSQL for persistent data storage

## 📚 Additional Resources

- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- [Jenkins Pipeline Documentation](https://www.jenkins.io/doc/book/pipeline/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)

---

**Happy Deploying! 🎉**

For issues or questions, please create an issue in the GitHub repository.