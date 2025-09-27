# Copilot Instructions for Image Uploader

## Architecture Overview

This is a **hybrid image uploader application** with both Next.js and Express.js components:

- **Next.js 15** frontend with React 19 (`app/` directory structure)
- **Express.js** backend (`server.js`) - legacy component that may be replaced by Next.js API routes
- **Dual API systems**: Both Express routes and Next.js API routes (`app/api/`)
- **File storage**: Images stored in `public/uploads/`, metadata in `images.json`

## Tech Stack & Dependencies

- **UI Framework**: shadcn/ui with Radix UI primitives and Tailwind CSS v4
- **Theme System**: next-themes with CSS custom properties (oklch color space)
- **File Handling**: Multer (Express), native Node.js fs (Next.js APIs)
- **State Management**: React hooks (useState, useEffect)
- **Package Manager**: pnpm (see `pnpm-lock.yaml`)

## Critical File Structure

```
app/
├── api/                    # Next.js API routes (preferred)
│   ├── upload/route.ts    # POST /api/upload - file upload
│   └── images/            # Image management
│       ├── route.ts       # GET /api/images - list all
│       └── [id]/route.ts  # DELETE /api/images/[id]
├── page.tsx               # Main React component with file upload UI
└── globals.css            # Tailwind v4 with oklch color system

server.js                  # Express.js server (legacy, may be redundant)
components/ui/             # shadcn/ui components (auto-generated)
images.json               # File metadata storage (JSON array)
public/uploads/           # Uploaded image files
```

## Data Flow & Storage Patterns

### File Upload Process
1. **Frontend**: `app/page.tsx` handles file selection, drag-and-drop, progress tracking
2. **API**: `app/api/upload/route.ts` processes FormData, saves to `public/uploads/`
3. **Metadata**: Each upload updates `images.json` with `{id, name, filename, size, url, uploadedAt}`
4. **Storage**: Images in filesystem, metadata in JSON (no database)

### Image Management
- **List**: `GET /api/images` reads from `images.json`
- **Delete**: `DELETE /api/images/[id]` removes file + metadata entry
- **Serving**: Static files served from `public/uploads/` by Next.js

## Development Workflows

### Commands
```bash
pnpm dev          # Next.js development server (port 3000)
pnpm build        # Production build
pnpm start        # Production server
node server.js    # Express server (if using legacy backend)
```

### Key Configuration
- **Next.js**: ESLint/TypeScript errors ignored in build (`next.config.mjs`)
- **Images**: Unoptimized images enabled for static file serving
- **Uploads**: Max file size handled in API routes, file validation client-side

## Component & Styling Patterns

### UI Components
- **shadcn/ui**: Use `components/ui/` components, follow "new-york" style variant
- **Utilities**: `lib/utils.ts` provides `cn()` for className merging (clsx + tailwind-merge)
- **Imports**: Use `@/` path aliases (`@/components`, `@/lib`, etc.)

### Styling Approach
- **Tailwind v4**: Uses `@import "tailwindcss"` in `globals.css`
- **Colors**: CSS custom properties with oklch color space (not hex/rgb)
- **Dark Mode**: Handled by next-themes with `:is(.dark *)` variant
- **Animation**: tw-animate-css for enhanced animations

## File Upload Implementation Details

### Client-Side (`app/page.tsx`)
- Supports drag-and-drop and file input
- Real-time upload progress with XMLHttpRequest
- File validation (type, size) before upload
- State management for upload status, progress, file list

### Server-Side (`app/api/upload/route.ts`)
- Uses Node.js fs/promises for async file operations
- Generates unique filenames with timestamp + random number
- Validates file types server-side
- Updates JSON metadata atomically

### Metadata Structure
```typescript
interface ImageData {
  id: string        // UUID-like identifier
  name: string      // Original filename
  filename: string  // Stored filename
  size: number      // File size in bytes
  url: string       // Public URL path
  uploadedAt: string // ISO timestamp
}
```

## Common Patterns & Conventions

### Error Handling
- API routes return `{success: boolean, message?: string}` format
- Client-side shows toast notifications for upload status
- File system errors logged to console, graceful fallbacks

### TypeScript Usage
- Interface definitions for image data structure
- Next.js API route types (`NextRequest`, `NextResponse`)
- React component props with proper typing

### State Management
- Local component state with React hooks
- No global state management (Redux, Zustand, etc.)
- API calls with fetch, manual loading states

## Integration Points

### External Dependencies
- **Radix UI**: Headless component primitives
- **Lucide React**: Icon library (see `components.json`)
- **Vercel Analytics**: Performance tracking

### File System Dependencies
- **Critical**: `images.json` must be writable for metadata updates
- **Upload Directory**: `public/uploads/` must exist and be writable
- **Static Serving**: Next.js serves uploaded files automatically

## AWS Deployment & CI/CD Patterns

### S3 Integration
- **Storage Migration**: Images stored in AWS S3 instead of local `public/uploads/`
- **S3 Service**: `lib/s3.ts` provides upload, delete, and URL generation utilities
- **Environment Variables**: AWS credentials and bucket configuration in `.env.local`
- **API Updates**: Upload routes modified to use S3 SDK instead of filesystem

### Docker Configuration
- **Multi-stage Build**: Optimized Dockerfile with build and runtime stages
- **Static Files**: Next.js static export for containerized deployment
- **Environment**: Supports both development and production containers

### Kubernetes Deployment
- **Manifests**: Deployment, Service, Ingress, and ConfigMap YAML files
- **Secrets**: AWS credentials stored in Kubernetes secrets
- **Scaling**: Configured for horizontal pod autoscaling
- **Health Checks**: Readiness and liveness probes for reliability

### Jenkins CI/CD Pipeline
- **Stages**: Build → Test → Docker Build → Push → Deploy to K8s
- **Triggers**: Webhook-based builds on Git commits
- **Rollback**: Automated deployment rollback capabilities
- **Notifications**: Slack/email integration for build status

## Infrastructure Setup

### AWS Resources (Free Tier Optimized)
- **EC2 Instances**: t3.micro for K8s master and worker nodes
- **S3 Bucket**: Standard storage class with lifecycle policies
- **Security Groups**: Properly configured for K8s cluster communication
- **IAM Roles**: Least-privilege access for S3 operations

### Kubernetes Cluster
- **Setup**: kubeadm-based cluster on EC2 instances
- **Networking**: Flannel CNI for pod networking
- **Ingress**: NGINX ingress controller for external access
- **Storage**: Persistent volumes for application data

## Debugging & Development Notes

- **Dual Backend Issue**: Both Express.js and Next.js APIs exist - prioritize Next.js API routes
- **README Mismatch**: README describes Express-only setup, but codebase uses Next.js
- **Build Configuration**: TypeScript/ESLint errors ignored for rapid development
- **Package Manager**: Use `pnpm` (not npm/yarn) as evidenced by lockfile
- **Local vs. Production**: Use environment variables to switch between local and S3 storage
- **Kubernetes Debugging**: Use `kubectl logs` and `kubectl describe` for troubleshooting