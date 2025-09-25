import { type NextRequest, NextResponse } from "next/server"
import { existsSync, readFileSync, writeFileSync } from "fs"
import path from "path"
import { deleteFromS3, extractS3KeyFromUrl } from "@/lib/s3"

const METADATA_FILE = path.join(process.env.METADATA_PATH || process.cwd(), "images.json")

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

export async function DELETE(request: NextRequest, { params }: { params: { id: string } }) {
  try {
    const imageId = params.id
    const metadata = readMetadata()

    // Find the image to delete
    const imageIndex = metadata.findIndex((img: any) => img.id === imageId)

    if (imageIndex === -1) {
      return NextResponse.json({ success: false, message: "Image not found" }, { status: 404 })
    }

    const imageToDelete = metadata[imageIndex]

    // Delete from S3
    let s3Key = imageToDelete.s3Key
    
    // For backward compatibility, if s3Key doesn't exist, try to extract from URL or use filename
    if (!s3Key) {
      if (imageToDelete.url && imageToDelete.url.includes('s3')) {
        s3Key = extractS3KeyFromUrl(imageToDelete.url)
      } else {
        // Fallback to filename if it looks like an S3 key
        s3Key = imageToDelete.filename
      }
    }

    if (s3Key) {
      const deleteResult = await deleteFromS3(s3Key)
      if (!deleteResult.success) {
        console.warn(`Failed to delete S3 object: ${deleteResult.error}`)
        // Continue with metadata deletion even if S3 deletion fails
      }
    }

    // Remove from metadata
    metadata.splice(imageIndex, 1)

    // Save updated metadata
    writeMetadata(metadata)

    return NextResponse.json({
      success: true,
      message: "Image deleted successfully",
    })
  } catch (error) {
    console.error("Delete error:", error)
    return NextResponse.json({ success: false, message: "Failed to delete image" }, { status: 500 })
  }
}
