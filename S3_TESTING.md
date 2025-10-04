# S3 Setup and Testing Guide

## Option 1: Create S3 Bucket via AWS Console

1. Go to AWS Console: https://console.aws.amazon.com/s3/
2. Click "Create bucket"
3. Bucket name: `image-uploader-YOUR_NAME-$(Get-Date -Format "yyyyMMdd")`
4. Region: Select your preferred region (e.g., us-east-1)
5. Block Public Access: **Uncheck all** (or configure CORS properly)
6. Click "Create bucket"

## Option 2: Create S3 Bucket via AWS CLI

```powershell
# Install AWS CLI if not installed
# Download from: https://aws.amazon.com/cli/

# Configure AWS CLI
aws configure

# Create bucket
aws s3 mb s3://image-uploader-test-$(Get-Date -Format "yyyyMMdd") --region us-east-1

# Set CORS
aws s3api put-bucket-cors --bucket YOUR_BUCKET_NAME --cors-configuration file://s3-cors.json

# Make bucket public for reading (optional, for testing)
aws s3api put-bucket-policy --bucket YOUR_BUCKET_NAME --policy '{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::YOUR_BUCKET_NAME/images/*"
    }
  ]
}'
```

## Testing S3 Integration Locally

### Test 1: Verify AWS Credentials
```powershell
# Create a test script
@"
const { S3Client, ListBucketsCommand } = require('@aws-sdk/client-s3');

const client = new S3Client({
  region: process.env.AWS_REGION || 'us-east-1',
  credentials: {
    accessKeyId: process.env.AWS_ACCESS_KEY_ID,
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
  },
});

async function test() {
  try {
    const command = new ListBucketsCommand({});
    const response = await client.send(command);
    console.log('✓ AWS Credentials are valid!');
    console.log('Your buckets:', response.Buckets.map(b => b.Name));
  } catch (error) {
    console.error('✗ Error:', error.message);
  }
}

test();
"@ | Out-File -FilePath test-aws.js -Encoding utf8

# Run test
node test-aws.js

# Clean up
Remove-Item test-aws.js
```

### Test 2: Start Development Server
```powershell
pnpm run dev
```

Then open browser to: http://localhost:3000

### Test 3: Upload an Image
1. Visit http://localhost:3000
2. Click "Choose File" or drag an image
3. Click Upload
4. Check browser console for any errors
5. Check S3 bucket to verify image was uploaded

### Test 4: View Images
1. Refresh the page
2. You should see uploaded images in the grid
3. Images should load from S3 URLs

## Troubleshooting

### Error: "Access Denied"
- Check AWS credentials in .env
- Verify IAM user has S3 permissions
- Check bucket policy

### Error: "Bucket does not exist"
- Verify bucket name in .env
- Check if bucket exists: `aws s3 ls`

### Error: "CORS error"
- Apply CORS configuration: `aws s3api put-bucket-cors --bucket YOUR_BUCKET --cors-configuration file://s3-cors.json`

### Images not loading
- Check if bucket is public or configure signed URLs
- Verify image URLs in browser network tab
- Check S3 bucket policy

## Verify S3 Upload

```powershell
# List files in S3 bucket
aws s3 ls s3://YOUR_BUCKET_NAME/images/ --recursive

# Download a file to verify
aws s3 cp s3://YOUR_BUCKET_NAME/images/image-xxxxx.jpg test-download.jpg
```

## Next Steps After Local Testing

Once S3 integration works locally:
1. Commit and push changes to GitHub
2. Deploy to AWS EC2 with K3s
3. Configure Kubernetes secrets with AWS credentials
4. Deploy via Jenkins pipeline
