import { type NextRequest, NextResponse } from "next/server"
import { uploadToS3 } from "@/lib/s3"

export async function POST(request: NextRequest) {
  try {
    const formData = await request.formData()
    const file = formData.get("image") as File

    if (!file) {
      return NextResponse.json({ success: false, message: "No file uploaded" }, { status: 400 })
    }

    // Validate file type
    const allowedTypes = ["image/jpeg", "image/jpg", "image/png", "image/gif", "image/webp"]
    if (!allowedTypes.includes(file.type)) {
      return NextResponse.json(
        { success: false, message: "Only image files (JPEG, PNG, GIF, WebP) are allowed" },
        { status: 400 },
      )
    }

    // Validate file size (5MB limit)
    if (file.size > 5 * 1024 * 1024) {
      return NextResponse.json({ success: false, message: "File too large. Maximum size is 5MB." }, { status: 400 })
    }

    // Upload to S3
    const imageData = await uploadToS3(file)

    return NextResponse.json({
      success: true,
      url: imageData.url,
      data: imageData,
    })
  } catch (error) {
    console.error("Upload error:", error)
    return NextResponse.json({ 
      success: false, 
      message: error instanceof Error ? error.message : "Upload failed" 
    }, { status: 500 })
  }
}
