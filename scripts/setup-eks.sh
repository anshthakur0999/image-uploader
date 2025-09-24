#!/bin/bash

# AWS EKS Cluster Setup Script for Free Tier
# This script sets up a minimal EKS cluster using AWS free tier resources

set -e

# Configuration
CLUSTER_NAME="image-uploader-cluster"
REGION="us-east-1"
NODE_GROUP_NAME="image-uploader-nodes"
INSTANCE_TYPE="t3.small"  # Eligible for free tier
MIN_NODES=1
MAX_NODES=2
DESIRED_NODES=1

echo "🚀 Setting up EKS cluster: $CLUSTER_NAME"

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI is not installed. Please install it first."
    exit 1
fi

# Check if eksctl is installed
if ! command -v eksctl &> /dev/null; then
    echo "📦 Installing eksctl..."
    curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
    sudo mv /tmp/eksctl /usr/local/bin
fi

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo "📦 Installing kubectl..."
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/
fi

# Create EKS cluster
echo "🏗️  Creating EKS cluster (this will take 15-20 minutes)..."
eksctl create cluster \
    --name $CLUSTER_NAME \
    --region $REGION \
    --version 1.28 \
    --nodegroup-name $NODE_GROUP_NAME \
    --node-type $INSTANCE_TYPE \
    --nodes $DESIRED_NODES \
    --nodes-min $MIN_NODES \
    --nodes-max $MAX_NODES \
    --managed \
    --with-oidc \
    --ssh-access \
    --ssh-public-key ~/.ssh/id_rsa.pub \
    --full-ecr-access

# Update kubeconfig
echo "⚙️  Updating kubeconfig..."
aws eks update-kubeconfig --region $REGION --name $CLUSTER_NAME

# Install AWS Load Balancer Controller
echo "🔧 Installing AWS Load Balancer Controller..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.6.3/docs/install/iam_policy.json

# Create IAM service account
eksctl create iamserviceaccount \
    --cluster=$CLUSTER_NAME \
    --namespace=kube-system \
    --name=aws-load-balancer-controller \
    --role-name "AmazonEKSLoadBalancerControllerRole" \
    --attach-policy-arn=arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):policy/AWSLoadBalancerControllerIAMPolicy \
    --approve

# Install the controller
kubectl apply -f https://github.com/kubernetes-sigs/aws-load-balancer-controller/releases/download/v2.6.3/v2_6_3_full.yaml

# Patch the deployment
kubectl patch deployment aws-load-balancer-controller \
    -n kube-system \
    --type='json' \
    -p='[{"op": "replace", "path": "/spec/template/spec/containers/0/args", "value": ["--cluster-name='$CLUSTER_NAME'","--ingress-class=alb"]}]'

# Install NGINX Ingress Controller (alternative to ALB for free tier)
echo "🌐 Installing NGINX Ingress Controller..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/aws/deploy.yaml

# Wait for NGINX controller to be ready
kubectl wait --namespace ingress-nginx \
    --for=condition=ready pod \
    --selector=app.kubernetes.io/component=controller \
    --timeout=90s

echo "✅ EKS cluster setup completed!"
echo "📋 Cluster info:"
kubectl cluster-info
echo ""
echo "🔧 Next steps:"
echo "1. Update your Jenkinsfile with the correct cluster name and region"
echo "2. Set up Jenkins with AWS credentials"
echo "3. Configure Docker Hub or ECR credentials in Jenkins"
echo "4. Run your CI/CD pipeline!"