import { NextResponse } from "next/server"
import { existsSync, readFileSync } from "fs"
import path from "path"

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

export async function GET() {
  try {
    const metadata = readMetadata()
    return NextResponse.json(metadata)
  } catch (error) {
    console.error("Error fetching images:", error)
    return NextResponse.json({ success: false, message: "Failed to fetch images" }, { status: 500 })
  }
}
