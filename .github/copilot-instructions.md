# AI Agent Instructions for Image Uploader

## Project Overview
This is a **Next.js 15 + TypeScript** image uploader app with shadcn/ui components, **not** the Node.js/Express app described in README.md. The README is outdated and describes a different implementation.

## Architecture & Key Patterns

### Tech Stack
- **Frontend**: Next.js 15 (App Router), React 19, TypeScript
- **UI Library**: shadcn/ui with Radix UI primitives, Tailwind CSS v4
- **Storage**: File system storage in `public/uploads/` with JSON metadata in `images.json`
- **Build Tools**: pnpm, PostCSS, TypeScript 5

### File Structure Pattern
```
app/
├── api/                  # Next.js API routes (server-side)
│   ├── upload/route.ts   # POST /api/upload - file upload
│   ├── images/route.ts   # GET /api/images - list all images  
│   └── images/[id]/route.ts # DELETE /api/images/[id] - delete image
├── page.tsx             # Main image uploader UI (client-side)
└── layout.tsx           # Root layout with Geist fonts

components/ui/           # shadcn/ui components (generated, don't edit manually)
lib/utils.ts            # cn() utility for className merging
```

### Data Flow & Storage
- **File Upload**: Files saved to `public/uploads/` with unique timestamps
- **Metadata**: Single `images.json` file at project root stores all image metadata
- **File Naming**: Pattern `image-{timestamp}-{random}.{ext}` for uniqueness
- **Validation**: 5MB max, JPEG/PNG/GIF only, enforced in API route

### API Route Patterns
All API routes use Next.js 15 App Router conventions:
```typescript
// app/api/upload/route.ts
export async function POST(request: NextRequest) {
  const formData = await request.formData()
  const file = formData.get("image") as File
  // File processing logic...
}
```

### Component & Styling Conventions
- **shadcn/ui**: Use existing components in `components/ui/`, don't recreate
- **Styling**: Tailwind v4 with CSS variables, `cn()` for conditional classes
- **Client Components**: Mark with `"use client"` when using hooks/state
- **Icons**: Lucide React (`lucide-react` package)

## Development Workflow

### Commands
```bash
pnpm dev          # Development server (port 3000)
pnpm build        # Production build  
pnpm start        # Production server
pnpm lint         # ESLint (currently disabled in config)
```

### Key Configuration
- **TypeScript**: Strict mode enabled, build errors ignored in `next.config.mjs`
- **Images**: Unoptimized in Next.js config for static export compatibility
- **Fonts**: Geist Sans/Mono loaded in root layout

## Project-Specific Patterns

### File Upload Implementation
```typescript
// Key validation pattern used in app/api/upload/route.ts
const allowedTypes = ["image/jpeg", "image/jpg", "image/png", "image/gif"]
if (!allowedTypes.includes(file.type)) {
  return NextResponse.json({ success: false, message: "..." }, { status: 400 })
}
```

### Metadata Management
The app uses a simple JSON file approach instead of a database:
```typescript
// Pattern used across API routes
const METADATA_FILE = path.join(process.cwd(), "images.json")
function readMetadata() {
  // Always include error handling for file operations
  try {
    if (existsSync(METADATA_FILE)) {
      return JSON.parse(readFileSync(METADATA_FILE, "utf8"))
    }
  } catch (error) {
    console.error("Error reading metadata:", error)
  }
  return []
}
```

### Client-Side State Pattern
Main component uses multiple useState hooks for upload state:
```typescript
// Pattern from app/page.tsx
const [selectedFiles, setSelectedFiles] = useState<File[]>([])
const [uploadStatus, setUploadStatus] = useState<{
  message: string
  type: "success" | "error" | "loading" | ""
}>({ message: "", type: "" })
```

## Common Integration Points
- **File uploads**: Always use FormData with field name "image"
- **API responses**: Consistent `{ success: boolean, message?: string }` format
- **Error handling**: API routes return appropriate HTTP status codes
- **Image URLs**: Served from `/uploads/` path (public directory)

## Adding New Features
- **New API routes**: Follow Next.js App Router conventions in `app/api/`
- **UI components**: Use existing shadcn/ui components or add new ones with `npx shadcn@latest add [component]`
- **Client state**: Follow existing useState patterns for consistency
- **File operations**: Always include error handling and path validation