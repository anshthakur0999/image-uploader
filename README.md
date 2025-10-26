# Image Uploader - CI/CD with K3s and Jenkins

A Next.js image uploader application with AWS S3 integration, deployed on Kubernetes using Jenkins CI/CD pipeline.

**✅ Automatic deployments enabled with Jenkins Poll SCM!**

## 🚀 Features

- **Image Upload**: Upload images with drag-and-drop support
- **AWS S3 Storage**: Images stored securely in AWS S3
- **Responsive Grid**: Display uploaded images in a responsive grid
- **Docker Support**: Fully containerized application
- **Kubernetes Ready**: Production-ready K8s manifests
- **CI/CD Pipeline**: Automated deployment with Jenkins
- **Scalable**: Easy horizontal scaling with Kubernetes

## 📋 Prerequisites

- AWS Account with S3 access
- Docker Hub account
- GitHub account
- EC2 instance (t3.medium recommended)
- Basic knowledge of Kubernetes and Docker

## 🛠️ Tech Stack

- **Frontend/Backend**: Next.js 15, React 19, TypeScript
- **UI Components**: Radix UI, Tailwind CSS
- **Cloud Storage**: AWS S3
- **Containerization**: Docker
- **Orchestration**: Kubernetes (K3s)
- **CI/CD**: Jenkins
- **Cloud Provider**: AWS EC2

## 📦 Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/your-username/image-uploader.git
cd image-uploader
```

### 2. Install Dependencies

```bash
npm install
# or
pnpm install
```

### 3. Configure Environment Variables

```bash
cp .env.example .env
```

Edit `.env` with your AWS credentials:

```env
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key
AWS_S3_BUCKET_NAME=your-bucket-name
```

### 4. Run Locally

```bash
npm run dev
```

Visit [http://localhost:3000](http://localhost:3000)

## 🐳 Docker Deployment

```bash
# Build image
docker build -t image-uploader:latest .

# Run container
docker run -p 3000:3000 \
  -e AWS_REGION=us-east-1 \
  -e AWS_ACCESS_KEY_ID=your-key \
  -e AWS_SECRET_ACCESS_KEY=your-secret \
  -e AWS_S3_BUCKET_NAME=your-bucket \
  image-uploader:latest
```

## ☸️ Kubernetes Deployment

See [DEPLOYMENT.md](./DEPLOYMENT.md) for complete deployment guide.

### Quick Deploy

```bash
chmod +x scripts/*.sh
./scripts/deploy.sh
```

## 🔄 CI/CD Pipeline

Complete Jenkins pipeline for automated deployment:
1. Build Docker image
2. Push to Docker Hub
3. Deploy to K3s cluster
4. Verify deployment

See [DEPLOYMENT.md](./DEPLOYMENT.md) for setup instructions.

## 🔧 Useful Commands

```bash
# Kubernetes
kubectl get pods -n image-uploader
kubectl logs -f deployment/image-uploader -n image-uploader
kubectl scale deployment/image-uploader --replicas=3 -n image-uploader

# Docker
docker ps
docker logs <container-id>
```

## 📚 Documentation

- [DEPLOYMENT.md](./DEPLOYMENT.md) - Complete deployment guide
- [Jenkinsfile](./Jenkinsfile) - CI/CD pipeline
- [Kubernetes Manifests](./k8s/) - K8s configuration

## 💰 Cost Estimate

**Monthly AWS Costs:**
- EC2 t3.medium: ~$30-35
- S3 Storage: ~$0.023/GB
- **Total**: ~$35-40/month

## 📝 License
- Express.js for the REST API
- Multer for file upload handling
- Vanilla JavaScript for frontend interactions
- CSS Grid and Flexbox for responsive layout
- File system storage with JSON metadata

## Troubleshooting

1. **Port already in use**: Change the port by setting `PORT=3001 npm start`
2. **Upload fails**: Check file size (max 5MB) and type (JPEG/PNG/GIF only)
3. **Images not displaying**: Ensure the `uploads` directory has proper permissions
4. **Metadata issues**: Delete `images.json` to reset (will lose image references)
