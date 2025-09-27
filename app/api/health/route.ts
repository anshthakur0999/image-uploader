import { NextResponse } from "next/server"

export async function GET() {
  try {
    // Basic health check - you can add more sophisticated checks here
    return NextResponse.json(
      {
        status: "healthy",
        timestamp: new Date().toISOString(),
        uptime: process.uptime(),
        environment: process.env.NODE_ENV || "development",
        storageType: process.env.STORAGE_TYPE || "local",
      },
      { status: 200 }
    )
  } catch (error) {
    return NextResponse.json(
      {
        status: "unhealthy",
        timestamp: new Date().toISOString(),
        error: error instanceof Error ? error.message : "Unknown error",
      },
      { status: 500 }
    )
  }
}