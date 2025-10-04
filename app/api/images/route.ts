import { NextResponse } from "next/server"
import { listImagesFromS3 } from "@/lib/s3"

export async function GET() {
  try {
    const images = await listImagesFromS3()
    return NextResponse.json(images)
  } catch (error) {
    console.error("Error fetching images:", error)
    return NextResponse.json({ 
      success: false, 
      message: error instanceof Error ? error.message : "Failed to fetch images" 
    }, { status: 500 })
  }
}
