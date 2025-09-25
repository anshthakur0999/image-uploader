import { type NextRequest, NextResponse } from "next/server"
import { existsSync, readFileSync, writeFileSync } from "fs"
import path from "path"
import { uploadToS3, generateS3Key } from "@/lib/s3"

const METADATA_FILE = path.join(process.env.METADATA_PATH || process.cwd(), "images.json")

// No longer needed - files are uploaded to S3

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

    // Generate unique S3 key
    const s3Key = generateS3Key(file.name)

    // Upload to S3
    const uploadResult = await uploadToS3(file, s3Key, file.type)

    if (!uploadResult.success) {
      return NextResponse.json({ 
        success: false, 
        message: `Upload failed: ${uploadResult.error}` 
      }, { status: 500 })
    }

    // Read existing metadata
    const metadata = readMetadata()

    // Create new image metadata
    const imageData = {
      id: Date.now().toString(),
      name: file.name,
      filename: s3Key, // Store S3 key instead of local filename
      size: file.size,
      url: uploadResult.url!, // S3 URL instead of local path
      s3Key: s3Key, // Store S3 key for deletion
      uploadedAt: new Date().toISOString(),
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
