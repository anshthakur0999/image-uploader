# CI/CD Quick Reference

## Environment Variables for Jenkins

Update these in your Jenkinsfile before deploying:

```groovy
environment {
    DOCKER_REGISTRY = 'YOUR_DOCKERHUB_USERNAME'    // ← Change this
    IMAGE_NAME = "${DOCKER_REGISTRY}/image-uploader"
    DOCKER_CREDENTIALS = 'docker-hub-credentials'
    KUBECONFIG_CREDENTIALS = 'kubeconfig-credentials'
    AWS_REGION = 'us-east-1'                        // ← Change if needed
    EKS_CLUSTER_NAME = 'image-uploader-cluster'     // ← Change if needed
}
```

## AWS Free Tier Resources Used

| Service | Resource | Cost |
|---------|----------|------|
| EC2 | t2.micro (Jenkins) | Free tier |
| EKS | Control plane | $0.10/hour |
| EC2 | t3.small (1 node) | ~$0.0208/hour |
| EBS | gp2 storage | Free tier eligible |

**Estimated cost**: $15-25/month

## Quick Commands

```bash
# Deploy application
./scripts/deploy.sh deploy latest

# Check status
./scripts/deploy.sh status

# View logs
./scripts/deploy.sh logs

# Rollback
./scripts/deploy.sh rollback

# Cleanup
./scripts/deploy.sh cleanup
```

## Jenkins Pipeline Stages

1. **Checkout** - Get code from Git
2. **Install Dependencies** - pnpm install
3. **Lint & Type Check** - Code quality
4. **Build Application** - pnpm run build
5. **Build Docker Image** - Multi-stage Docker build
6. **Security Scan** - Trivy vulnerability scan
7. **Push Docker Image** - To Docker Hub
8. **Deploy to Kubernetes** - Apply K8s manifests
9. **Health Check** - Verify deployment

## File Structure

```
├── Dockerfile                 # Multi-stage container build
├── Jenkinsfile               # CI/CD pipeline definition
├── DEPLOYMENT.md             # Complete setup guide
├── k8s/                      # Kubernetes manifests
│   ├── namespace.yaml
│   ├── configmap.yaml
│   ├── pvc.yaml
│   ├── deployment.yaml
│   ├── service.yaml
│   └── ingress.yaml
└── scripts/                  # Helper scripts
    ├── setup-eks.sh         # EKS cluster setup
    ├── setup-jenkins.sh     # Jenkins installation
    └── deploy.sh            # Deployment helper
```