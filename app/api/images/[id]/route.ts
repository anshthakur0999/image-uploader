import { type NextRequest, NextResponse } from "next/server"
import { unlink } from "fs/promises"
import { existsSync, readFileSync, writeFileSync } from "fs"
import path from "path"

const UPLOAD_DIR = path.join(process.cwd(), "public/uploads")
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

    // Delete the physical file
    const filePath = path.join(UPLOAD_DIR, imageToDelete.filename)
    if (existsSync(filePath)) {
      await unlink(filePath)
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
