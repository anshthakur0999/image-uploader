# AWS Setup Checklist

Use this checklist while setting up AWS for the first time.

## Pre-Setup
- [ ] Have AWS account (create at https://aws.amazon.com if needed)
- [ ] Can login to AWS Console
- [ ] Have credit card on file (free tier available)

## Part 1: Create IAM User

### In AWS Console:
- [ ] Navigate to IAM: https://console.aws.amazon.com/iam/
- [ ] Click "Users" in left sidebar
- [ ] Click "Create user" button
- [ ] Enter username: `image-uploader-s3-user`
- [ ] Click "Next"

### Set Permissions:
- [ ] Select "Attach policies directly"
- [ ] Search for: `AmazonS3FullAccess`
- [ ] Check the box next to AmazonS3FullAccess
- [ ] Click "Next"
- [ ] Click "Create user"

### Create Access Keys:
- [ ] Click on the username you just created
- [ ] Click "Security credentials" tab
- [ ] Scroll to "Access keys" section
- [ ] Click "Create access key"
- [ ] Select "Application running outside AWS"
- [ ] Check confirmation box
- [ ] Click "Next"
- [ ] Click "Create access key"

### Save Credentials (IMPORTANT!):
- [ ] Copy Access Key ID: ________________
- [ ] Copy Secret Access Key: ________________
- [ ] Download .csv file (recommended)
- [ ] Save to password manager or secure location
- [ ] Click "Done"

## Part 2: Create S3 Bucket

### In AWS Console:
- [ ] Navigate to S3: https://console.aws.amazon.com/s3/
- [ ] Click "Create bucket"
- [ ] Enter bucket name (must be unique): ________________
      Suggestion: `image-uploader-yourname-20251004`
- [ ] Select region: ________________ (e.g., us-east-1)
- [ ] Uncheck "Block all public access" (for testing only)
- [ ] Check the warning acknowledgment
- [ ] Leave other settings as default
- [ ] Click "Create bucket"
- [ ] Note your bucket name: ________________

## Part 3: Configure CORS (Optional but Recommended)

### Via AWS Console:
- [ ] Click on your bucket name
- [ ] Go to "Permissions" tab
- [ ] Scroll to "Cross-origin resource sharing (CORS)"
- [ ] Click "Edit"
- [ ] Paste this configuration:
```json
[
    {
        "AllowedHeaders": ["*"],
        "AllowedMethods": ["GET", "PUT", "POST", "DELETE", "HEAD"],
        "AllowedOrigins": ["*"],
        "ExposeHeaders": ["ETag"],
        "MaxAgeSeconds": 3000
    }
]
```
- [ ] Click "Save changes"

## Part 4: Update Local Configuration

### Update .env file:
- [ ] Open .env file: `notepad .env`
- [ ] Update AWS_REGION: ________________
- [ ] Update AWS_ACCESS_KEY_ID: ________________
- [ ] Update AWS_SECRET_ACCESS_KEY: ________________
- [ ] Update AWS_S3_BUCKET_NAME: ________________
- [ ] Save file

Your .env should look like:
```env
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
AWS_S3_BUCKET_NAME=image-uploader-yourname-20251004
NEXT_PUBLIC_API_URL=http://localhost:3000
```

## Part 5: Test AWS Connection

### Run test script:
- [ ] Open PowerShell in project directory
- [ ] Run: `node test-s3-connection.js`
- [ ] Verify "AWS Credentials are valid!" message
- [ ] Verify "Bucket exists and is accessible!" message
- [ ] Verify "Successfully uploaded test file!" message
- [ ] All tests should pass with ✅

### If tests fail:
- [ ] Double-check .env values
- [ ] Verify IAM user permissions
- [ ] Verify bucket exists and name is correct
- [ ] Check AWS_IAM_SETUP.md troubleshooting section

## Part 6: Test Local Application

### Start development server:
- [ ] Run: `pnpm run dev`
- [ ] Open browser: http://localhost:3000
- [ ] Application loads without errors

### Test image upload:
- [ ] Click "Choose File" or drag an image
- [ ] Select a test image (JPG, PNG, or GIF)
- [ ] Click "Upload" button
- [ ] See success message
- [ ] Image appears in the grid
- [ ] No errors in browser console (F12)

### Verify in S3:
- [ ] Go to AWS S3 Console
- [ ] Click on your bucket
- [ ] See "images/" folder
- [ ] Click into images/ folder
- [ ] See your uploaded image file
- [ ] File size looks correct

## Part 7: Security Verification

- [ ] .env file is in .gitignore (should be)
- [ ] Access keys are NOT in any code files
- [ ] Downloaded credentials CSV is in a secure location
- [ ] Noted AWS region for future reference

## Troubleshooting Checklist

If upload fails:
- [ ] Check browser console (F12) for errors
- [ ] Check terminal where dev server is running
- [ ] Verify .env values are correct
- [ ] Restart dev server: Ctrl+C then `pnpm run dev`
- [ ] Try uploading a different image
- [ ] Check image file size (should be under 5MB)

If "Access Denied" error:
- [ ] Verify IAM user has AmazonS3FullAccess policy
- [ ] Check access keys are copied correctly
- [ ] No extra spaces in .env values
- [ ] Regenerate access keys if needed

If "Bucket not found" error:
- [ ] Bucket name is spelled correctly
- [ ] Bucket name matches exactly (case-sensitive)
- [ ] Bucket exists in the specified region
- [ ] Region in .env matches bucket region

## Success Criteria

✅ All items checked above
✅ Test script passes all tests
✅ Can upload image via web interface
✅ Image appears in grid
✅ Image exists in S3 bucket
✅ No errors in console

## Next Steps After Success

- [ ] Review AWS_IAM_SETUP.md for security best practices
- [ ] Consider restricting IAM policy to specific bucket
- [ ] Set up billing alerts in AWS
- [ ] Document your bucket name and region
- [ ] Proceed with Kubernetes deployment (DEPLOYMENT.md)

---

## Quick Commands

```powershell
# Edit .env
notepad .env

# Test connection
node test-s3-connection.js

# Start dev server
pnpm run dev

# View logs (in new terminal)
# Check terminal where dev server is running
```

---

**Completion Date:** ____________

**Notes:**
- Bucket name: ________________
- Region: ________________
- IAM user: image-uploader-s3-user
- Test image uploaded: ✅ / ❌

---

**Having issues?** Check:
1. AWS_IAM_SETUP.md - Full setup guide
2. S3_TESTING.md - Testing guide
3. TROUBLESHOOTING.md - Common issues
