import { S3Client, PutObjectCommand, DeleteObjectCommand, GetObjectCommand } from "@aws-sdk/client-s3"
import { getSignedUrl } from "@aws-sdk/s3-request-presigner"

// Initialize S3 client
const s3Client = new S3Client({
  region: process.env.AWS_REGION || "us-east-1",
  credentials: {
    accessKeyId: process.env.AWS_ACCESS_KEY_ID!,
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY!,
  },
})

const BUCKET_NAME = process.env.AWS_S3_BUCKET_NAME!

export interface UploadResult {
  success: boolean
  url?: string
  key?: string
  error?: string
}

/**
 * Upload file to S3 bucket
 */
export async function uploadToS3(
  file: File,
  key: string,
  contentType: string = file.type
): Promise<UploadResult> {
  try {
    const bytes = await file.arrayBuffer()
    const buffer = Buffer.from(bytes)

    const command = new PutObjectCommand({
      Bucket: BUCKET_NAME,
      Key: key,
      Body: buffer,
      ContentType: contentType,
      // No ACL since bucket doesn't allow ACLs - use presigned URLs for access
    })

    await s3Client.send(command)

    // Generate a presigned URL for secure access (valid for 7 days)
    const presignedResult = await generatePresignedUrl(key, 7 * 24 * 3600) // 7 days
    const url = presignedResult.success ? presignedResult.url! : `https://${BUCKET_NAME}.s3.${process.env.AWS_REGION || "us-east-1"}.amazonaws.com/${key}`

    return {
      success: true,
      url,
      key,
    }
  } catch (error) {
    console.error("Error uploading to S3:", error)
    return {
      success: false,
      error: error instanceof Error ? error.message : "Unknown error",
    }
  }
}

/**
 * Delete file from S3 bucket
 */
export async function deleteFromS3(key: string): Promise<{ success: boolean; error?: string }> {
  try {
    const command = new DeleteObjectCommand({
      Bucket: BUCKET_NAME,
      Key: key,
    })

    await s3Client.send(command)

    return { success: true }
  } catch (error) {
    console.error("Error deleting from S3:", error)
    return {
      success: false,
      error: error instanceof Error ? error.message : "Unknown error",
    }
  }
}

/**
 * Generate presigned URL for secure access
 * Useful for private objects without public ACLs
 */
export async function generatePresignedUrl(
  key: string,
  expiresIn: number = 3600 // 1 hour by default
): Promise<{ success: boolean; url?: string; error?: string }> {
  try {
    const command = new GetObjectCommand({
      Bucket: BUCKET_NAME,
      Key: key,
    })

    const url = await getSignedUrl(s3Client, command, { expiresIn })

    return {
      success: true,
      url,
    }
  } catch (error) {
    console.error("Error generating presigned URL:", error)
    return {
      success: false,
      error: error instanceof Error ? error.message : "Unknown error",
    }
  }
}

/**
 * Generate unique S3 key for uploaded files
 */
export function generateS3Key(originalFilename: string, prefix: string = "uploads"): string {
  const uniqueSuffix = Date.now() + "-" + Math.round(Math.random() * 1e9)
  const ext = originalFilename.split(".").pop()
  return `${prefix}/image-${uniqueSuffix}.${ext}`
}

/**
 * Extract S3 key from S3 URL
 */
export function extractS3KeyFromUrl(url: string): string | null {
  try {
    // Handle both formats:
    // https://bucket.s3.region.amazonaws.com/key
    // https://s3.region.amazonaws.com/bucket/key
    // Also handle presigned URLs with query parameters
    const urlParts = new URL(url)
    
    if (urlParts.hostname.includes('.s3.')) {
      // Format: https://bucket.s3.region.amazonaws.com/key
      return urlParts.pathname.substring(1) // Remove leading slash
    } else if (urlParts.hostname.includes('s3.')) {
      // Format: https://s3.region.amazonaws.com/bucket/key
      const pathParts = urlParts.pathname.split('/')
      return pathParts.slice(2).join('/') // Remove empty string and bucket name
    }
    
    return null
  } catch (error) {
    console.error("Error extracting S3 key from URL:", error)
    return null
  }
}

/**
 * Check if a presigned URL is expired or will expire soon
 */
export function isUrlExpiredOrExpiring(url: string, bufferHours: number = 24): boolean {
  try {
    const urlParts = new URL(url)
    const expiresParam = urlParts.searchParams.get('X-Amz-Expires')
    const dateParam = urlParts.searchParams.get('X-Amz-Date')
    
    if (!expiresParam || !dateParam) {
      // Not a presigned URL or missing parameters
      return false
    }
    
    const expiresSeconds = parseInt(expiresParam)
    const signedDate = new Date(
      dateParam.substring(0, 4) + '-' +
      dateParam.substring(4, 6) + '-' +
      dateParam.substring(6, 8) + 'T' +
      dateParam.substring(9, 11) + ':' +
      dateParam.substring(11, 13) + ':' +
      dateParam.substring(13, 15) + 'Z'
    )
    
    const expiryDate = new Date(signedDate.getTime() + expiresSeconds * 1000)
    const bufferTime = new Date(Date.now() + bufferHours * 60 * 60 * 1000)
    
    return expiryDate <= bufferTime
  } catch (error) {
    console.error("Error checking URL expiry:", error)
    return true // Assume expired if we can't parse
  }
}