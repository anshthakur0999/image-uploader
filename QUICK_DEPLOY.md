# Quick Deployment Guide

Your AWS EKS deployment is ready! 

## Steps to Deploy:

### 1. Set GitHub Secrets
In your GitHub repo → Settings → Secrets → Actions, add:
- `AWS_ACCESS_KEY_ID` 
- `AWS_SECRET_ACCESS_KEY`

### 2. Deploy Locally (Alternative)
```bash
# Set environment variables with your AWS credentials
export AWS_ACCESS_KEY_ID=your-access-key
export AWS_SECRET_ACCESS_KEY=your-secret-key  
export AWS_S3_BUCKET_NAME=your-image-uploader-bucket

# Run deployment
./scripts/deploy-local.sh
```

### 3. Push to GitHub
```bash
git push origin main
```

GitHub Actions will automatically build and deploy to your EKS cluster!

## Check Deployment
```bash
kubectl get pods -n image-uploader
kubectl get svc -n image-uploader
```