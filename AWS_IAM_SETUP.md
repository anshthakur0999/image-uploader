# AWS IAM User Setup Guide for S3 Access

## Step-by-Step: Create IAM User with S3 Permissions

### Option 1: AWS Console (Recommended for Beginners)

#### Step 1: Login to AWS Console
1. Go to: https://console.aws.amazon.com/
2. Sign in with your AWS account

#### Step 2: Navigate to IAM
1. In the search bar at the top, type **IAM**
2. Click on **IAM** (Identity and Access Management)
3. Or go directly to: https://console.aws.amazon.com/iam/

#### Step 3: Create New User
1. In the left sidebar, click **Users**
2. Click the **Create user** button (orange button, top right)
3. Enter User name: `image-uploader-s3-user`
4. Click **Next**

#### Step 4: Set Permissions
Choose one of these options:

**Option A: Use AWS Managed Policy (Quick & Easy)**
1. Select **Attach policies directly**
2. In the search box, type: `AmazonS3FullAccess`
3. Check the box next to **AmazonS3FullAccess**
4. Click **Next**

**Option B: Create Custom Policy (More Secure, Recommended)**
1. Select **Attach policies directly**
2. Click **Create policy** (opens in new tab)
3. Click on the **JSON** tab
4. Replace the content with this policy:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "ImageUploaderS3Access",
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:DeleteObject",
                "s3:ListBucket",
                "s3:GetBucketLocation",
                "s3:ListAllMyBuckets"
            ],
            "Resource": [
                "arn:aws:s3:::*",
                "arn:aws:s3:::*/*"
            ]
        }
    ]
}
```

5. Click **Next**
6. Policy name: `ImageUploaderS3Policy`
7. Description: `Allows image uploader app to access S3 buckets`
8. Click **Create policy**
9. Go back to the previous tab (Create user)
10. Click the refresh icon next to "Create policy"
11. Search for: `ImageUploaderS3Policy`
12. Check the box next to it
13. Click **Next**

#### Step 5: Review and Create
1. Review the user details
2. Click **Create user**

#### Step 6: Create Access Keys
1. Click on the username you just created (`image-uploader-s3-user`)
2. Click on the **Security credentials** tab
3. Scroll down to **Access keys** section
4. Click **Create access key**
5. Select **Application running outside AWS**
6. Check the confirmation box
7. Click **Next**
8. (Optional) Add description: "Image uploader application"
9. Click **Create access key**

#### Step 7: Save Your Credentials ⚠️ IMPORTANT!
**This is the ONLY time you can see the Secret Access Key!**

You'll see:
- **Access key ID** - Example: `AKIAIOSFODNN7EXAMPLE`
- **Secret access key** - Example: `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY`

**Save these immediately:**

1. Click **Download .csv file** (recommended)
2. OR copy both values to a secure location
3. Click **Done**

---

### Option 2: AWS CLI (For Advanced Users)

```bash
# 1. Install AWS CLI if not installed
# Download from: https://aws.amazon.com/cli/

# 2. Configure AWS CLI
aws configure
# Enter your AWS credentials when prompted

# 3. Create IAM user
aws iam create-user --user-name image-uploader-s3-user

# 4. Create custom policy
cat > image-uploader-policy.json << 'EOF'
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "ImageUploaderS3Access",
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:DeleteObject",
                "s3:ListBucket",
                "s3:GetBucketLocation",
                "s3:ListAllMyBuckets"
            ],
            "Resource": [
                "arn:aws:s3:::*",
                "arn:aws:s3:::*/*"
            ]
        }
    ]
}
EOF

# 5. Create policy
aws iam create-policy \
    --policy-name ImageUploaderS3Policy \
    --policy-document file://image-uploader-policy.json

# 6. Get your AWS account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# 7. Attach policy to user
aws iam attach-user-policy \
    --user-name image-uploader-s3-user \
    --policy-arn arn:aws:iam::${AWS_ACCOUNT_ID}:policy/ImageUploaderS3Policy

# 8. Create access keys
aws iam create-access-key --user-name image-uploader-s3-user

# Save the output! You'll see AccessKeyId and SecretAccessKey
```

---

## Create S3 Bucket

### Option 1: AWS Console

1. Go to: https://console.aws.amazon.com/s3/
2. Click **Create bucket**
3. **Bucket name**: `image-uploader-yourname-20251004` (must be globally unique)
4. **AWS Region**: Select your preferred region (e.g., `us-east-1`)
5. **Block Public Access settings**: 
   - For testing: Uncheck "Block all public access"
   - Check the acknowledgment box
6. **Bucket Versioning**: Disabled (or Enabled for production)
7. **Encryption**: Enable (Server-side encryption with Amazon S3 managed keys)
8. Click **Create bucket**

### Option 2: AWS CLI

```bash
# Replace YOUR_BUCKET_NAME with your actual bucket name
BUCKET_NAME="image-uploader-yourname-20251004"

# Create bucket
aws s3 mb s3://$BUCKET_NAME --region us-east-1

# Set bucket policy (allow public read for images)
cat > bucket-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::$BUCKET_NAME/images/*"
        }
    ]
}
EOF

aws s3api put-bucket-policy --bucket $BUCKET_NAME --policy file://bucket-policy.json

# Configure CORS
aws s3api put-bucket-cors --bucket $BUCKET_NAME --cors-configuration file://s3-cors.json

echo "Bucket created: $BUCKET_NAME"
```

---

## Configure Your Application

### Step 1: Update .env File

Open `.env` and add your credentials:

```env
# AWS Configuration
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
AWS_S3_BUCKET_NAME=image-uploader-yourname-20251004

# Application
NEXT_PUBLIC_API_URL=http://localhost:3000
```

### Step 2: Test Connection

```bash
node test-s3-connection.js
```

### Step 3: Start Dev Server

```bash
pnpm run dev
```

### Step 4: Test Upload
1. Open http://localhost:3000
2. Upload an image
3. Verify it appears in the grid
4. Check S3 bucket to confirm upload

---

## Verify S3 Bucket Access

### Via AWS Console
1. Go to S3: https://console.aws.amazon.com/s3/
2. Click on your bucket name
3. You should see an `images/` folder after uploading

### Via AWS CLI
```bash
# List all buckets
aws s3 ls

# List contents of your bucket
aws s3 ls s3://YOUR_BUCKET_NAME/

# List uploaded images
aws s3 ls s3://YOUR_BUCKET_NAME/images/ --recursive
```

---

## Security Best Practices

### 1. Restrict Policy to Specific Bucket (After Testing)

Update the policy to only allow access to your specific bucket:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:DeleteObject",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::YOUR_BUCKET_NAME",
                "arn:aws:s3:::YOUR_BUCKET_NAME/*"
            ]
        }
    ]
}
```

### 2. Never Commit .env File
- `.env` is already in `.gitignore`
- Never share your access keys publicly
- Rotate keys regularly

### 3. Use IAM Roles in Production
- For EC2: Use IAM roles instead of access keys
- More secure than hardcoded credentials

### 4. Enable MFA for IAM User
- Add extra security layer
- Go to IAM → Users → Security credentials → Assign MFA device

---

## Troubleshooting

### Error: "Access Denied"
- Verify IAM policy is attached to user
- Check bucket policy allows your operations
- Ensure access keys are correct

### Error: "Bucket not found"
- Check bucket name spelling
- Verify bucket exists: `aws s3 ls`
- Check region matches

### Error: "Invalid Access Key"
- Regenerate access keys
- Update .env file
- Restart dev server

### CORS Errors
- Apply CORS configuration to bucket
- Check browser console for specific CORS error
- Verify s3-cors.json is properly configured

---

## Quick Reference

### PowerShell Commands
```powershell
# Copy .env template
Copy-Item .env.example .env

# Edit .env
notepad .env

# Test connection
node test-s3-connection.js

# Start dev server
pnpm run dev
```

### AWS CLI Commands
```bash
# List buckets
aws s3 ls

# Create bucket
aws s3 mb s3://bucket-name

# Upload file
aws s3 cp file.jpg s3://bucket-name/

# List bucket contents
aws s3 ls s3://bucket-name/images/

# Delete bucket (careful!)
aws s3 rb s3://bucket-name --force
```

---

## Next Steps After Setup

1. ✅ Create IAM user
2. ✅ Create S3 bucket
3. ✅ Update .env file
4. ✅ Test connection: `node test-s3-connection.js`
5. ✅ Start dev server: `pnpm run dev`
6. ✅ Upload test image
7. ✅ Verify in S3 bucket
8. 🚀 Ready for deployment!

---

## Cost Estimate

**S3 Pricing (us-east-1):**
- Storage: $0.023 per GB/month
- PUT requests: $0.005 per 1,000 requests
- GET requests: $0.0004 per 1,000 requests
- Data transfer out: First 1 GB free, then $0.09/GB

**Example for 1,000 images (5 MB each):**
- Storage (5 GB): $0.12/month
- Requests: ~$0.01/month
- **Total: ~$0.15/month**

Very affordable! 💰

---

**Need help? Check the troubleshooting section or refer to AWS documentation:**
- IAM: https://docs.aws.amazon.com/IAM/
- S3: https://docs.aws.amazon.com/s3/
