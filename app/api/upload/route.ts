import { type NextRequest, NextResponse } from "next/server"
import { writeFile, mkdir } from "fs/promises"
import { existsSync, readFileSync, writeFileSync } from "fs"
import path from "path"
import { uploadToS3, isS3Configured } from "@/lib/s3"

const UPLOAD_DIR = path.join(process.cwd(), "public/uploads")
const METADATA_FILE = path.join(process.cwd(), "images.json")

// Ensure upload directory exists
async function ensureUploadDir() {
  if (!existsSync(UPLOAD_DIR)) {
    await mkdir(UPLOAD_DIR, { recursive: true })
  }
}

// Helper functions for metadata
function readMetadata() {
  try {
    if (existsSync(METADATA_FILE)) {
      const data = readFileSync(METADATA_FILE, "utf8")
      return JSON.parse(data)
    }
  } catch (error) {
    console.error("Error reading metadata:", error)
  }
  return []
}

function writeMetadata(metadata: any[]) {
  try {
    writeFileSync(METADATA_FILE, JSON.stringify(metadata, null, 2))
  } catch (error) {
    console.error("Error writing metadata:", error)
  }
}

export async function POST(request: NextRequest) {
  try {
    const formData = await request.formData()
    const file = formData.get("image") as File

    if (!file) {
      return NextResponse.json({ success: false, message: "No file uploaded" }, { status: 400 })
    }

    // Validate file type
    const allowedTypes = ["image/jpeg", "image/jpg", "image/png", "image/gif"]
    if (!allowedTypes.includes(file.type)) {
      return NextResponse.json(
        { success: false, message: "Only image files (JPEG, PNG, GIF) are allowed" },
        { status: 400 },
      )
    }

    // Validate file size (5MB limit)
    if (file.size > 5 * 1024 * 1024) {
      return NextResponse.json({ success: false, message: "File too large. Maximum size is 5MB." }, { status: 400 })
    }

    const bytes = await file.arrayBuffer()
    const buffer = Buffer.from(bytes)
    
    // Check if S3 is configured and STORAGE_TYPE is set to 's3'
    const useS3 = process.env.STORAGE_TYPE === 's3' && isS3Configured()
    
    let imageUrl: string
    let s3Key: string | undefined

    if (useS3) {
      // Upload to S3
      const s3Result = await uploadToS3(buffer, file.name, file.type)
      
      if (!s3Result.success) {
        return NextResponse.json(
          { success: false, message: s3Result.error || "S3 upload failed" },
          { status: 500 }
        )
      }
      
      imageUrl = s3Result.url!
      s3Key = s3Result.key
    } else {
      // Upload to local filesystem (fallback)
      await ensureUploadDir()
      
      const uniqueSuffix = Date.now() + "-" + Math.round(Math.random() * 1e9)
      const ext = path.extname(file.name)
      const filename = `image-${uniqueSuffix}${ext}`
      const filepath = path.join(UPLOAD_DIR, filename)
      
      await writeFile(filepath, buffer)
      imageUrl = `/uploads/${filename}`
    }

    // Read existing metadata
    const metadata = readMetadata()

    // Create new image metadata
    const imageData = {
      id: Date.now().toString(),
      name: file.name,
      filename: s3Key || path.basename(imageUrl),
      size: file.size,
      url: imageUrl,
      uploadedAt: new Date().toISOString(),
      storageType: useS3 ? 's3' : 'local',
      ...(s3Key && { s3Key })
    }

    // Add to metadata array
    metadata.push(imageData)

    // Save metadata
    writeMetadata(metadata)

    return NextResponse.json({
      success: true,
      url: imageData.url,
    })
  } catch (error) {
    console.error("Upload error:", error)
    return NextResponse.json({ success: false, message: "Upload failed" }, { status: 500 })
  }
}
