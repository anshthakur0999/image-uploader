# Image Uploader

A **Ne- **Error Handling**: Comprehensive error messages and validation

## 🏗️ Infrastructure

### Production Deployment
- **Platform**: AWS EKS (Kubernetes)
- **Container Registry**: Docker Hub (`anshthakur503/image-uploader`)
- **CI/CD**: GitHub Actions
- **Load Balancer**: AWS Application Load Balancer
- **Node Type**: t3.small (1 instance)

### Deployment Status
```
✅ EKS Cluster: image-uploader-cluster (us-east-1)
✅ Application: Running (1/1 pods)
✅ Service: LoadBalancer active
✅ CI/CD Pipeline: GitHub Actions enabled
✅ Container: anshthakur503/image-uploader:latest
```

## 🚀 Quick Start

### Local Development
```bash
# Install dependencies
pnpm install

# Start development server
pnpm run devScript** image uploader application with complete CI/CD pipeline deployment on AWS EKS.

## 🚀 Live Application
**URL**: http://ae1a167b4233347bd968540879ee85e2-1516540849.us-east-1.elb.amazonaws.com

## 📚 Documentation
- **[Complete Deployment Guide](DEPLOYMENT_GUIDE.md)** - Step-by-step CI/CD setup with AWS EKS
- **[Quick Reference](QUICK_REFERENCE.md)** - Essential commands and troubleshooting
- **[Copilot Instructions](.github/copilot-instructions.md)** - AI agent guidance for development

## ⚡ Tech Stack
- **Frontend**: Next.js 15, React 19, TypeScript, shadcn/ui, Tailwind CSS v4
- **Infrastructure**: AWS EKS, Docker, GitHub Actions
- **Storage**: File system with JSON metadata

## Features

- **File Upload**: Upload images via file input or drag-and-drop
- **File Validation**: Accepts only JPEG, PNG, and GIF files (max 5MB each)
- **Image Gallery**: Responsive grid layout displaying uploaded images
- **Image Management**: View image details and delete images
- **Progress Tracking**: Real-time upload progress indicators
- **Error Handling**: Comprehensive error messages and validation

## Tech Stack

- **Backend**: Node.js, Express.js, Multer
- **Frontend**: HTML5, CSS3, Vanilla JavaScript
- **Storage**: File system with JSON metadata

## Installation

1. Clone or download the project files
2. Install dependencies:
   \`\`\`bash
   npm install
   \`\`\`

## Usage

1. Start the server:
   \`\`\`bash
   npm start
   \`\`\`
   
   For development with auto-restart:
   \`\`\`bash
   npm run dev
   \`\`\`

2. Open your browser and navigate to:
   \`\`\`
   http://localhost:3000
   \`\`\`

## API Endpoints

### POST /upload
Upload an image file.
- **Content-Type**: `multipart/form-data`
- **Field**: `image` (file)
- **Response**: `{ success: true, url: "/uploads/<filename>" }`

### GET /images
Get all uploaded images metadata.
- **Response**: Array of image objects with `{id, name, size, url, uploadedAt}`

### DELETE /images/:id
Delete an image by ID.
- **Response**: `{ success: true, message: "Image deleted successfully" }`

## File Structure

\`\`\`
image-uploader/
├── server.js          # Express server
├── package.json       # Dependencies and scripts
├── images.json        # Image metadata storage
├── uploads/           # Uploaded images directory
└── public/            # Frontend files
    ├── index.html     # Main HTML page
    ├── styles.css     # Styling
    └── app.js         # Frontend JavaScript
\`\`\`

## Configuration

- **Port**: Default 3000 (set `PORT` environment variable to change)
- **Upload Directory**: `./uploads`
- **Max File Size**: 5MB per image
- **Allowed Types**: JPEG, PNG, GIF

## Browser Support

- Modern browsers with ES6+ support
- File API and FormData support required
- Drag and drop API support for enhanced UX

## Development

The application uses:
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
