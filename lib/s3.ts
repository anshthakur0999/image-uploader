import { S3Client, PutObjectCommand, GetObjectCommand, ListObjectsV2Command, DeleteObjectCommand } from "@aws-sdk/client-s3"
import { getSignedUrl } from "@aws-sdk/s3-request-presigner"

// Initialize S3 client
const s3Client = new S3Client({
  region: process.env.AWS_REGION || "us-east-1",
  credentials: {
    accessKeyId: process.env.AWS_ACCESS_KEY_ID || "",
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY || "",
  },
})

const BUCKET_NAME = process.env.AWS_S3_BUCKET_NAME || ""

export interface S3ImageMetadata {
  id: string
  name: string
  filename: string
  size: number
  url: string
  uploadedAt: string
}

/**
 * Upload an image to S3
 */
export async function uploadToS3(file: File): Promise<S3ImageMetadata> {
  const uniqueSuffix = Date.now() + "-" + Math.round(Math.random() * 1e9)
  const ext = file.name.split(".").pop()
  const filename = `images/image-${uniqueSuffix}.${ext}`

  const bytes = await file.arrayBuffer()
  const buffer = Buffer.from(bytes)

  const uploadCommand = new PutObjectCommand({
    Bucket: BUCKET_NAME,
    Key: filename,
    Body: buffer,
    ContentType: file.type,
    Metadata: {
      originalName: file.name,
      uploadedAt: new Date().toISOString(),
    },
  })

  await s3Client.send(uploadCommand)

  // Generate signed URL for secure access (valid for 1 hour)
  const url = await getSignedImageUrl(filename, 3600)

  return {
    id: filename,
    name: file.name,
    filename,
    size: file.size,
    url,
    uploadedAt: new Date().toISOString(),
  }
}

/**
 * Get a signed URL for an image (for secure access to private buckets)
 */
export async function getSignedImageUrl(key: string, expiresIn: number = 3600): Promise<string> {
  const command = new GetObjectCommand({
    Bucket: BUCKET_NAME,
    Key: key,
  })

  const signedUrl = await getSignedUrl(s3Client, command, { expiresIn })
  return signedUrl
}

/**
 * List all images from S3
 */
export async function listImagesFromS3(): Promise<S3ImageMetadata[]> {
  const listCommand = new ListObjectsV2Command({
    Bucket: BUCKET_NAME,
    Prefix: "images/",
  })

  const response = await s3Client.send(listCommand)
  const images: S3ImageMetadata[] = []

  if (response.Contents) {
    for (const item of response.Contents) {
      if (item.Key && item.Size && item.LastModified) {
        // Generate signed URL for secure access (valid for 1 hour)
        const url = await getSignedImageUrl(item.Key, 3600)
        
        images.push({
          id: item.Key,
          name: item.Key.split("/").pop() || item.Key,
          filename: item.Key,
          size: item.Size,
          url,
          uploadedAt: item.LastModified.toISOString(),
        })
      }
    }
  }

  // Sort by upload date (newest first)
  images.sort((a, b) => new Date(b.uploadedAt).getTime() - new Date(a.uploadedAt).getTime())

  return images
}

/**
 * Delete an image from S3
 */
export async function deleteFromS3(key: string): Promise<void> {
  const deleteCommand = new DeleteObjectCommand({
    Bucket: BUCKET_NAME,
    Key: key,
  })

  await s3Client.send(deleteCommand)
}
