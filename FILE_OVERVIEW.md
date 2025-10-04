# Project File Overview

## Complete File Structure

```
image-uploader/
│
├── app/                                    # Next.js App Directory
│   ├── api/                               # API Routes
│   │   ├── images/                        # Images API
│   │   │   ├── route.ts                  # ✨ MODIFIED - List images from S3
│   │   │   └── [id]/
│   │   │       └── route.ts              # Individual image operations
│   │   └── upload/
│   │       └── route.ts                  # ✨ MODIFIED - Upload to S3
│   ├── globals.css                        # Global styles
│   ├── layout.tsx                         # Root layout
│   └── page.tsx                          # Main page component
│
├── components/                            # React Components
│   ├── theme-provider.tsx
│   └── ui/                               # UI Components (Radix/Shadcn)
│       ├── accordion.tsx
│       ├── alert-dialog.tsx
│       ├── button.tsx
│       ├── card.tsx
│       ├── dialog.tsx
│       ├── input.tsx
│       └── ... (other UI components)
│
├── hooks/                                 # Custom React Hooks
│   ├── use-mobile.ts
│   └── use-toast.ts
│
├── k8s/                                  # ✨ NEW - Kubernetes Manifests
│   ├── 00-namespace-secrets.yaml        # Namespace, secrets, ConfigMaps
│   ├── 01-deployment.yaml               # Application deployment
│   ├── 02-service.yaml                  # NodePort service
│   ├── 03-ingress.yaml                  # Ingress configuration
│   └── 04-cert-manager-issuer.yaml      # SSL/TLS certificates
│
├── lib/                                  # Utility Libraries
│   ├── s3.ts                            # ✨ NEW - AWS S3 integration
│   └── utils.ts                         # Helper functions
│
├── public/                               # Static Files
│   ├── app.js
│   ├── index.html
│   ├── styles.css
│   └── placeholder images
│
├── scripts/                              # ✨ NEW - Deployment Scripts
│   ├── setup-server.sh                  # Automated server setup
│   ├── deploy.sh                        # Quick deployment
│   ├── update-deployment.sh             # Update running deployment
│   ├── rollback.sh                      # Rollback deployment
│   ├── logs.sh                          # View application logs
│   ├── cleanup.sh                       # Clean up resources
│   └── validate.sh                      # Pre-deployment validation
│
├── styles/                               # Additional Styles
│   └── globals.css
│
├── .github/                              # ✨ NEW - GitHub Actions
│   └── workflows/
│       └── ci-cd.yml                    # CI/CD workflow
│
├── .dockerignore                         # ✨ NEW - Docker ignore rules
├── .env.example                          # ✨ NEW - Environment template
├── .gitignore                           # Git ignore rules
├── CHECKLIST.md                          # ✨ NEW - Deployment checklist
├── COMMANDS.md                           # ✨ NEW - Command reference
├── components.json                       # Shadcn UI config
├── DEPLOYMENT.md                         # ✨ NEW - Complete deployment guide
├── Dockerfile                            # ✨ NEW - Multi-stage Docker build
├── images.json                          # Image metadata (local dev)
├── Jenkinsfile                           # ✨ NEW - Jenkins pipeline
├── next.config.mjs                       # ✨ MODIFIED - Added standalone output
├── package.json                          # ✨ MODIFIED - Added AWS SDK
├── pnpm-lock.yaml                       # Package lock file
├── postcss.config.mjs                   # PostCSS configuration
├── README.md                             # ✨ MODIFIED - Updated documentation
├── s3-cors.json                          # ✨ NEW - S3 CORS configuration
├── server.js                            # Express server
├── SETUP_SUMMARY.md                      # ✨ NEW - Setup summary
├── TROUBLESHOOTING.md                    # ✨ NEW - Troubleshooting guide
└── tsconfig.json                        # TypeScript configuration
```

## Key Files Explained

### Core Application Files

#### `lib/s3.ts` (✨ NEW)
- AWS S3 integration utilities
- Functions: uploadToS3, listImagesFromS3, deleteFromS3, getSignedImageUrl
- Handles all S3 operations

#### `app/api/upload/route.ts` (✨ MODIFIED)
- Upload API endpoint
- Now uploads to S3 instead of local filesystem
- Validates file type and size
- Returns S3 URL

#### `app/api/images/route.ts` (✨ MODIFIED)
- List images API endpoint
- Fetches image list from S3
- Returns image metadata

#### `package.json` (✨ MODIFIED)
- Added AWS SDK dependencies:
  - @aws-sdk/client-s3
  - @aws-sdk/s3-request-presigner

#### `next.config.mjs` (✨ MODIFIED)
- Added `output: 'standalone'` for Docker
- Added S3 image domain patterns

### Docker & CI/CD Files

#### `Dockerfile` (✨ NEW)
- Multi-stage build for optimization
- Stage 1: Dependencies
- Stage 2: Build
- Stage 3: Runtime
- Non-root user for security
- Optimized for Next.js standalone mode

#### `.dockerignore` (✨ NEW)
- Excludes unnecessary files from Docker image
- Reduces image size
- Excludes node_modules, .git, .env files

#### `Jenkinsfile` (✨ NEW)
- Complete CI/CD pipeline definition
- Stages:
  1. Checkout code
  2. Build Docker image
  3. Push to Docker Hub
  4. Deploy to Kubernetes
  5. Verify deployment
- Automatic rollback on failure

#### `.github/workflows/ci-cd.yml` (✨ NEW)
- Alternative to Jenkins using GitHub Actions
- Same workflow: build → test → deploy
- Automatically triggered on push

### Kubernetes Files

#### `k8s/00-namespace-secrets.yaml` (✨ NEW)
- Creates namespace: `image-uploader`
- Defines AWS credentials as secrets
- ConfigMap for environment variables

#### `k8s/01-deployment.yaml` (✨ NEW)
- Deployment with 2 replicas
- Health checks (liveness/readiness)
- Resource limits (CPU/memory)
- Environment variables from secrets/ConfigMaps

#### `k8s/02-service.yaml` (✨ NEW)
- NodePort service (port 30080)
- Exposes application externally
- Load balances across pods

#### `k8s/03-ingress.yaml` (✨ NEW)
- Ingress configuration
- Domain-based routing
- Proxy settings for file uploads

#### `k8s/04-cert-manager-issuer.yaml` (✨ NEW)
- Let's Encrypt SSL/TLS configuration
- Automatic certificate management
- Production and staging issuers

### Deployment Scripts

#### `scripts/setup-server.sh` (✨ NEW)
- Automated server setup
- Installs: Docker, K3s, Jenkins, kubectl, Helm
- Configures all services
- One-command setup

#### `scripts/deploy.sh` (✨ NEW)
- Quick deployment script
- Interactive prompts for configuration
- Builds and deploys application
- Shows deployment status

#### `scripts/update-deployment.sh` (✨ NEW)
- Updates running deployment
- Rolling update with new image
- Zero downtime

#### `scripts/rollback.sh` (✨ NEW)
- Rolls back to previous version
- Shows rollout history
- Safe rollback mechanism

#### `scripts/logs.sh` (✨ NEW)
- View application logs
- Follow logs in real-time
- Can target specific pod

#### `scripts/cleanup.sh` (✨ NEW)
- Deletes all Kubernetes resources
- Cleanup for fresh deployment
- Confirmation required

#### `scripts/validate.sh` (✨ NEW)
- Pre-deployment validation
- Checks all requirements
- Verifies configuration
- Warns about missing values

### Documentation Files

#### `DEPLOYMENT.md` (✨ NEW)
- **Most important documentation file**
- Complete step-by-step guide
- 10 parts covering everything:
  1. AWS Setup
  2. Server Setup
  3. Application Deployment
  4. Verification & Testing
  5. Monitoring & Maintenance
  6. Troubleshooting
  7. Cost Optimization
  8. Security Best Practices
  9. Production Enhancements
  10. Next Steps

#### `README.md` (✨ MODIFIED)
- Updated project overview
- Quick start guide
- Tech stack information
- Basic deployment instructions

#### `SETUP_SUMMARY.md` (✨ NEW)
- High-level summary
- Architecture diagram
- Quick reference
- Cost breakdown

#### `COMMANDS.md` (✨ NEW)
- Command reference guide
- All useful commands in one place
- Organized by category
- Copy-paste ready

#### `TROUBLESHOOTING.md` (✨ NEW)
- Common issues and solutions
- 10 major issue categories
- Diagnostic commands
- Emergency procedures

#### `CHECKLIST.md` (✨ NEW)
- Step-by-step checklist
- Checkbox format
- Pre-deployment verification
- Post-deployment tasks

### Configuration Files

#### `.env.example` (✨ NEW)
- Template for environment variables
- Documents required variables
- Copy to .env for local development

#### `s3-cors.json` (✨ NEW)
- S3 CORS configuration
- Allows browser uploads
- Used with AWS CLI

## Files You Need to Modify

Before deployment, update these files with your values:

### 1. `k8s/00-namespace-secrets.yaml`
```yaml
AWS_REGION: "us-east-1"           # Your AWS region
AWS_ACCESS_KEY_ID: "your-key"     # Your AWS access key
AWS_SECRET_ACCESS_KEY: "your-secret"  # Your AWS secret
AWS_S3_BUCKET_NAME: "your-bucket"     # Your S3 bucket name
```

### 2. `k8s/01-deployment.yaml`
```yaml
image: your-dockerhub-username/image-uploader:latest
```

### 3. `Jenkinsfile`
```groovy
DOCKER_IMAGE_NAME = 'your-dockerhub-username/image-uploader'
```

### 4. `.env` (create from .env.example)
```env
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-access-key
AWS_S3_BUCKET_NAME=your-bucket-name
```

## File Permissions

Make scripts executable:
```bash
chmod +x scripts/*.sh
```

## Files to NOT Commit

The `.gitignore` file excludes:
- `.env` (contains secrets)
- `node_modules/`
- `.next/` (build output)
- `uploads/` (local uploads)
- `images.json` (local metadata)
- `*.kubeconfig` (cluster access)

## Architecture Overview

```
┌─────────────────────────────────────────────────────┐
│                     GitHub                          │
│              (Source Code Repository)               │
└─────────────────┬───────────────────────────────────┘
                  │
                  │ Push/Webhook
                  ▼
┌─────────────────────────────────────────────────────┐
│                    Jenkins                          │
│              (CI/CD Automation)                     │
│                                                     │
│  Jenkinsfile → Build → Test → Deploy               │
└─────────────────┬───────────────────────────────────┘
                  │
                  │ Docker Push
                  ▼
┌─────────────────────────────────────────────────────┐
│                  Docker Hub                         │
│            (Container Registry)                     │
└─────────────────┬───────────────────────────────────┘
                  │
                  │ Image Pull
                  ▼
┌─────────────────────────────────────────────────────┐
│                K3s Kubernetes                       │
│              (Container Orchestration)              │
│                                                     │
│  ┌──────────────────────────────────────────┐     │
│  │         Deployment (2 Replicas)          │     │
│  │  ┌────────────┐      ┌────────────┐     │     │
│  │  │   Pod 1    │      │   Pod 2    │     │     │
│  │  │ (App + S3) │      │ (App + S3) │     │     │
│  │  └────────────┘      └────────────┘     │     │
│  └──────────────────────────────────────────┘     │
│                                                     │
│  ┌──────────────────────────────────────────┐     │
│  │        Service (NodePort 30080)          │     │
│  └──────────────────────────────────────────┘     │
└─────────────────┬───────────────────────────────────┘
                  │
                  │ Image Storage
                  ▼
┌─────────────────────────────────────────────────────┐
│                  AWS S3 Bucket                      │
│              (Image Storage)                        │
└─────────────────────────────────────────────────────┘
```

## Quick Start Commands

```bash
# Validate setup
./scripts/validate.sh

# Deploy application
./scripts/deploy.sh

# View logs
./scripts/logs.sh

# Update deployment
./scripts/update-deployment.sh v2

# Rollback
./scripts/rollback.sh

# Cleanup
./scripts/cleanup.sh
```

## Next Steps

1. Read `DEPLOYMENT.md` for complete instructions
2. Follow `CHECKLIST.md` step-by-step
3. Use `COMMANDS.md` for reference
4. Refer to `TROUBLESHOOTING.md` if issues arise
5. Run `scripts/validate.sh` before deploying

## Support

For detailed help, see:
- `DEPLOYMENT.md` - Complete deployment guide
- `TROUBLESHOOTING.md` - Issue resolution
- `COMMANDS.md` - Command reference
- `CHECKLIST.md` - Step-by-step checklist
