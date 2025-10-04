import { type NextRequest, NextResponse } from "next/server"
import { deleteFromS3, listImagesFromS3, type S3ImageMetadata } from "@/lib/s3"

export async function DELETE(request: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  try {
    // In Next.js 15, params is a Promise
    const { id } = await params
    // Decode the URL-encoded imageId
    const imageId = decodeURIComponent(id)
    
    // The imageId is actually the S3 key (filename)
    // Delete from S3
    await deleteFromS3(imageId)

    return NextResponse.json({
      success: true,
      message: "Image deleted successfully",
    })
  } catch (error) {
    console.error("Delete error:", error)
    return NextResponse.json(
      { 
        success: false, 
        message: error instanceof Error ? error.message : "Failed to delete image" 
      }, 
      { status: 500 }
    )
  }
}

export async function GET(request: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  try {
    // In Next.js 15, params is a Promise
    const { id } = await params
    // Decode the URL-encoded imageId
    const imageId = decodeURIComponent(id)
    
    const images = await listImagesFromS3()
    
    const image = images.find((img: S3ImageMetadata) => img.id === imageId || img.filename === imageId)
    
    if (!image) {
      return NextResponse.json({ success: false, message: "Image not found" }, { status: 404 })
    }

    return NextResponse.json(image)
  } catch (error) {
    console.error("Error fetching image:", error)
    return NextResponse.json(
      { 
        success: false, 
        message: error instanceof Error ? error.message : "Failed to fetch image" 
      }, 
      { status: 500 }
    )
  }
}


