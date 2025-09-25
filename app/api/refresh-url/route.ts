import { type NextRequest, NextResponse } from "next/server"
import { generatePresignedUrl } from "@/lib/s3"

export async function POST(request: NextRequest) {
  try {
    const { s3Key } = await request.json()

    if (!s3Key) {
      return NextResponse.json({ success: false, message: "S3 key is required" }, { status: 400 })
    }

    // Generate new presigned URL (valid for 7 days)
    const result = await generatePresignedUrl(s3Key, 7 * 24 * 3600)

    if (!result.success) {
      return NextResponse.json({ 
        success: false, 
        message: `Failed to generate URL: ${result.error}` 
      }, { status: 500 })
    }

    return NextResponse.json({
      success: true,
      url: result.url,
    })
  } catch (error) {
    console.error("Presigned URL generation error:", error)
    return NextResponse.json({ success: false, message: "Failed to generate URL" }, { status: 500 })
  }
}