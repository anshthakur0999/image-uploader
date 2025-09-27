import { S3Client, PutObjectCommand, DeleteObjectCommand, GetObjectCommand } from '@aws-sdk/client-s3'
import { getSignedUrl } from '@aws-sdk/s3-request-presigner'

const s3Client = new S3Client({
  region: process.env.AWS_REGION || 'us-east-1',
  credentials: {
    accessKeyId: process.env.AWS_ACCESS_KEY_ID!,
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY!,
  },
})

const BUCKET_NAME = process.env.AWS_S3_BUCKET_NAME!

export interface S3UploadResult {
  success: boolean
  url?: string
  key?: string
  error?: string
}

export interface S3DeleteResult {
  success: boolean
  error?: string
}

/**
 * Upload a file to S3
 * @param file - File buffer
 * @param fileName - Name for the file in S3
 * @param contentType - MIME type of the file
 * @returns Upload result with URL and key
 */
export async function uploadToS3(
  file: Buffer,
  fileName: string,
  contentType: string
): Promise<S3UploadResult> {
  try {
    // Generate unique filename with timestamp
    const timestamp = Date.now()
    const randomNum = Math.floor(Math.random() * 100000000)
    const fileExtension = fileName.split('.').pop()
    const uniqueFileName = `images/image-${timestamp}-${randomNum}.${fileExtension}`

    const command = new PutObjectCommand({
      Bucket: BUCKET_NAME,
      Key: uniqueFileName,
      Body: file,
      ContentType: contentType,
      // Make files publicly readable
      ACL: 'public-read',
      // Optional: Add metadata
      Metadata: {
        originalName: fileName,
        uploadedAt: new Date().toISOString(),
      },
    })

    await s3Client.send(command)

    // Construct public URL
    const publicUrl = `https://${BUCKET_NAME}.s3.${process.env.AWS_REGION || 'us-east-1'}.amazonaws.com/${uniqueFileName}`

    return {
      success: true,
      url: publicUrl,
      key: uniqueFileName,
    }
  } catch (error) {
    console.error('S3 upload error:', error)
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Unknown upload error',
    }
  }
}

/**
 * Delete a file from S3
 * @param key - S3 object key to delete
 * @returns Delete result
 */
export async function deleteFromS3(key: string): Promise<S3DeleteResult> {
  try {
    const command = new DeleteObjectCommand({
      Bucket: BUCKET_NAME,
      Key: key,
    })

    await s3Client.send(command)

    return {
      success: true,
    }
  } catch (error) {
    console.error('S3 delete error:', error)
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Unknown delete error',
    }
  }
}

/**
 * Generate a presigned URL for temporary access to a private file
 * @param key - S3 object key
 * @param expiresIn - URL expiration time in seconds (default: 3600 = 1 hour)
 * @returns Presigned URL
 */
export async function getPresignedUrl(key: string, expiresIn: number = 3600): Promise<string> {
  try {
    const command = new GetObjectCommand({
      Bucket: BUCKET_NAME,
      Key: key,
    })

    const signedUrl = await getSignedUrl(s3Client, command, { expiresIn })
    return signedUrl
  } catch (error) {
    console.error('Error generating presigned URL:', error)
    throw error
  }
}

/**
 * Extract S3 key from public URL
 * @param url - Public S3 URL
 * @returns S3 key or null if invalid URL
 */
export function extractS3Key(url: string): string | null {
  try {
    // Handle different S3 URL formats
    const s3UrlRegex = /https:\/\/.*\.s3\..*\.amazonaws\.com\/(.+)/
    const match = url.match(s3UrlRegex)
    return match ? match[1] : null
  } catch (error) {
    console.error('Error extracting S3 key:', error)
    return null
  }
}

/**
 * Check if S3 is properly configured
 * @returns Configuration status
 */
export function isS3Configured(): boolean {
  return !!(
    process.env.AWS_ACCESS_KEY_ID &&
    process.env.AWS_SECRET_ACCESS_KEY &&
    process.env.AWS_S3_BUCKET_NAME &&
    process.env.AWS_REGION
  )
}