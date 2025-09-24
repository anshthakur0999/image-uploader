# Complete CI/CD Pipeline Guide: Next.js Image Uploader on AWS EKS

## 🎯 Overview

This guide walks you through deploying a **Next.js 15 + TypeScript** image uploader application using a complete CI/CD pipeline with:
- **GitHub Actions** for CI/CD
- **Docker Hub** for container registry
- **AWS EKS** for Kubernetes orchestration
- **AWS LoadBalancer** for external access

## 📋 Prerequisites

### Required Accounts & Tools
- ✅ **AWS Account** (Free Tier eligible)
- ✅ **Docker Hub Account**
- ✅ **GitHub Account**
- ✅ **Local Tools:**
  - AWS CLI v2
  - kubectl
  - eksctl
  - Docker Desktop
  - Git
  - Node.js 18+ & pnpm

## 🚀 Step-by-Step Implementation

### Phase 1: AWS Setup

#### 1.1 Configure AWS CLI
```bash
# Install AWS CLI v2 and configure
aws configure
# Enter your AWS Access Key ID
# Enter your AWS Secret Access Key
# Default region: us-east-1
# Default output format: json

# Verify configuration
aws sts get-caller-identity
```

#### 1.2 Create EKS Cluster
```bash
# Create EKS cluster with worker nodes
eksctl create cluster \
  --name image-uploader-cluster \
  --region us-east-1 \
  --nodegroup-name image-uploader-nodes \
  --node-type t3.small \
  --nodes 1 \
  --nodes-min 1 \
  --nodes-max 2 \
  --with-oidc \
  --ssh-access \
  --ssh-public-key YOUR_KEY_NAME \
  --managed

# Verify cluster
kubectl get nodes
```

### Phase 2: Application Setup

#### 2.1 Project Structure
```
image-uploader/
├── .github/workflows/ci-cd.yml     # GitHub Actions pipeline
├── k8s/                            # Kubernetes manifests
│   ├── namespace.yaml
│   ├── deployment-simple.yaml
│   └── service.yaml
├── Dockerfile                      # Container definition
├── next.config.mjs                # Next.js configuration
└── [Next.js app files...]
```

#### 2.2 Critical Configuration Files

**Dockerfile** (Multi-stage optimized):
```dockerfile
# Build stage
FROM node:18-alpine AS builder
WORKDIR /app
RUN npm install -g pnpm
COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile
COPY . .
RUN pnpm run build

# Production stage
FROM node:18-alpine AS runner
WORKDIR /app
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs
COPY --from=builder /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static
USER nextjs
EXPOSE 3000
ENV PORT 3000
ENV HOSTNAME "0.0.0.0"
CMD ["node", "server.js"]
```

**next.config.mjs** (Standalone output):
```javascript
/** @type {import('next').NextConfig} */
const nextConfig = {
  output: 'standalone',
  images: {
    unoptimized: true,
  },
  typescript: {
    ignoreBuildErrors: true,
  },
};

export default nextConfig;
```

### Phase 3: GitHub Actions CI/CD Pipeline

#### 3.1 Workflow Configuration
**`.github/workflows/ci-cd.yml`**:
```yaml
name: CI/CD Pipeline

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

env:
  DOCKER_REGISTRY: YOUR_DOCKERHUB_USERNAME
  IMAGE_NAME: image-uploader
  AWS_REGION: us-east-1
  EKS_CLUSTER_NAME: image-uploader-cluster

jobs:
  build-and-test:
    runs-on: ubuntu-latest
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
      
    - name: Setup Node.js
      uses: actions/setup-node@v4
      with:
        node-version: '18'
        
    - name: Install pnpm
      run: npm install -g pnpm
      
    - name: Get pnpm store directory
      shell: bash
      run: echo "STORE_PATH=$(pnpm store path --silent)" >> $GITHUB_ENV
        
    - name: Setup pnpm cache
      uses: actions/cache@v3
      with:
        path: ${{ env.STORE_PATH }}
        key: ${{ runner.os }}-pnpm-store-${{ hashFiles('**/pnpm-lock.yaml') }}
        restore-keys: |
          ${{ runner.os }}-pnpm-store-
      
    - name: Install dependencies
      run: pnpm install --frozen-lockfile
      
    - name: Build application
      run: pnpm run build

  build-docker:
    needs: build-and-test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
      
    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v3
      
    - name: Login to Docker Hub
      uses: docker/login-action@v3
      with:
        username: ${{ secrets.DOCKER_HUB_USERNAME }}
        password: ${{ secrets.DOCKER_HUB_ACCESS_TOKEN }}
        
    - name: Build and push Docker image
      uses: docker/build-push-action@v5
      with:
        context: .
        platforms: linux/amd64
        push: true
        tags: |
          ${{ env.DOCKER_REGISTRY }}/${{ env.IMAGE_NAME }}:latest
          ${{ env.DOCKER_REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}
        cache-from: type=gha
        cache-to: type=gha,mode=max

  deploy:
    needs: build-docker
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
      
    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v4
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: ${{ env.AWS_REGION }}
        
    - name: Update kubeconfig
      run: |
        aws eks update-kubeconfig --region ${{ env.AWS_REGION }} --name ${{ env.EKS_CLUSTER_NAME }}
        kubectl get nodes
        
    - name: Deploy to EKS
      run: |
        # Apply Kubernetes manifests
        kubectl apply -f k8s/namespace.yaml
        kubectl apply -f k8s/deployment.yaml
        kubectl apply -f k8s/service.yaml
        
        # Wait for deployment to be ready
        kubectl rollout status deployment/image-uploader-deployment -n image-uploader --timeout=300s
        
        # Get service URL
        kubectl get service image-uploader-service -n image-uploader
```

#### 3.2 GitHub Repository Secrets
Configure these secrets in your GitHub repository (`Settings > Secrets and variables > Actions`):

```
AWS_ACCESS_KEY_ID=AKIA...
AWS_SECRET_ACCESS_KEY=...
DOCKER_HUB_USERNAME=your-dockerhub-username
DOCKER_HUB_ACCESS_TOKEN=dckr_pat_...
```

### Phase 4: Kubernetes Manifests

#### 4.1 Namespace
**`k8s/namespace.yaml`**:
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: image-uploader
  labels:
    name: image-uploader
```

#### 4.2 Deployment
**`k8s/deployment-simple.yaml`**:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: image-uploader-deployment
  namespace: image-uploader
  labels:
    app: image-uploader
spec:
  replicas: 1
  selector:
    matchLabels:
      app: image-uploader
  template:
    metadata:
      labels:
        app: image-uploader
    spec:
      containers:
      - name: image-uploader
        image: YOUR_DOCKERHUB_USERNAME/image-uploader:latest
        ports:
        - containerPort: 3000
        env:
        - name: NODE_ENV
          value: "production"
        - name: PORT
          value: "3000"
        - name: NEXT_TELEMETRY_DISABLED
          value: "1"
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "200m"
        livenessProbe:
          httpGet:
            path: /
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /
            port: 3000
          initialDelaySeconds: 5
          periodSeconds: 5
```

#### 4.3 Service (LoadBalancer)
**`k8s/service.yaml`**:
```yaml
apiVersion: v1
kind: Service
metadata:
  name: image-uploader-service
  namespace: image-uploader
  labels:
    app: image-uploader
spec:
  selector:
    app: image-uploader
  ports:
    - protocol: TCP
      port: 80
      targetPort: 3000
  type: LoadBalancer
```

### Phase 5: Deployment Process

#### 5.1 Initial Setup Commands
```bash
# 1. Clone and setup repository
git clone https://github.com/YOUR_USERNAME/image-uploader.git
cd image-uploader

# 2. Install dependencies
pnpm install

# 3. Test locally
pnpm run dev

# 4. Build and test Docker image locally
docker build -t image-uploader .
docker run -p 3000:3000 image-uploader

# 5. Deploy Kubernetes manifests
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/deployment-simple.yaml
kubectl apply -f k8s/service.yaml
```

#### 5.2 Verification Commands
```bash
# Check cluster status
kubectl get nodes

# Check application pods
kubectl get pods -n image-uploader

# Check service and get LoadBalancer URL
kubectl get service image-uploader-service -n image-uploader

# View application logs
kubectl logs -f deployment/image-uploader-deployment -n image-uploader

# Check application health
curl -I http://YOUR_LOADBALANCER_URL
```

## 🛠️ Troubleshooting Guide

### Common Issues & Solutions

#### 1. Docker Image Pull Failures
**Problem**: `ErrImagePull` or `ImagePullBackOff`
**Solutions**:
- Verify Docker Hub username in workflow
- Check GitHub secrets are correctly set
- Ensure image was successfully pushed to Docker Hub
- Use `docker pull YOUR_USERNAME/image-uploader:latest` to test locally

#### 2. Pod Stuck in Pending State
**Problem**: Pods not scheduling
**Solutions**:
- Check node resources: `kubectl describe nodes`
- Verify persistent volume claims if using storage
- Check pod events: `kubectl describe pod POD_NAME -n image-uploader`

#### 3. Service Not Accessible
**Problem**: LoadBalancer URL not responding
**Solutions**:
- Verify service port mapping (80 → 3000)
- Check pod readiness: `kubectl get pods -n image-uploader`
- Ensure security groups allow traffic on port 80
- Wait for LoadBalancer provisioning (5-10 minutes)

#### 4. GitHub Actions Failures
**Problem**: Workflow steps failing
**Solutions**:
- Check pnpm cache configuration
- Verify AWS credentials in GitHub secrets
- Ensure EKS cluster name matches workflow
- Review workflow logs for specific errors

## 📊 Architecture Overview

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Developer     │───▶│   GitHub Repo    │───▶│  GitHub Actions │
│   (git push)    │    │                  │    │   (CI/CD)       │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                                         │
                                                         ▼
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│     Users       │◀───│  AWS LoadBalancer│◀───│   Docker Hub    │
│   (Browser)     │    │    (ELB)         │    │   (Registry)    │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                 │                       │
                                 ▼                       ▼
                       ┌──────────────────┐    ┌─────────────────┐
                       │   EKS Cluster    │◀───│  Kubernetes     │
                       │  (t3.small)      │    │  (Deployment)   │
                       └──────────────────┘    └─────────────────┘
```

## 💰 Cost Optimization

### AWS Free Tier Usage
- **EKS Cluster**: $0.10/hour (after free tier)
- **EC2 t3.small**: ~$0.0208/hour
- **LoadBalancer**: ~$0.025/hour
- **Total**: ~$1.10/day ($33/month)

### Cost Reduction Tips
1. **Use t3.micro for dev** (if sufficient resources)
2. **Stop cluster when not needed**: `eksctl delete cluster --name image-uploader-cluster`
3. **Use spot instances** for non-production workloads
4. **Monitor AWS billing dashboard** regularly

## 🎉 Success Criteria

Your deployment is successful when:
- ✅ GitHub Actions workflow completes without errors
- ✅ Docker image is pushed to Docker Hub
- ✅ EKS cluster shows healthy nodes
- ✅ Pod status is `Running` (1/1 Ready)
- ✅ LoadBalancer has external IP assigned
- ✅ Application responds at LoadBalancer URL
- ✅ Next.js logs show "Ready in Xms"

## 🔄 Maintenance & Updates

### Regular Tasks
```bash
# Update dependencies
pnpm update

# Check security vulnerabilities
pnpm audit

# Update Kubernetes cluster
eksctl upgrade cluster --name image-uploader-cluster

# Monitor resource usage
kubectl top nodes
kubectl top pods -n image-uploader
```

### Scaling Operations
```bash
# Scale pods
kubectl scale deployment image-uploader-deployment --replicas=3 -n image-uploader

# Scale cluster nodes
eksctl scale nodegroup --cluster=image-uploader-cluster --name=image-uploader-nodes --nodes=2
```

## 📚 Additional Resources

- [Next.js Deployment Documentation](https://nextjs.org/docs/deployment)
- [EKS User Guide](https://docs.aws.amazon.com/eks/latest/userguide/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Docker Hub Documentation](https://docs.docker.com/docker-hub/)
- [kubectl Reference](https://kubernetes.io/docs/reference/kubectl/)

---

**🎊 Congratulations!** You now have a production-ready CI/CD pipeline for your Next.js application on AWS EKS!