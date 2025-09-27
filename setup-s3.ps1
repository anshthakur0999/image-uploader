# PowerShell S3 Setup Script
# Run this in PowerShell with AWS CLI configured

$BUCKET_NAME = "image-uploader-bucket-$(Get-Date -Format 'yyyyMMddHHmmss')"
$AWS_REGION = "us-east-1"
$POLICY_NAME = "ImageUploaderS3Policy"
$USER_NAME = "image-uploader-s3-user"

Write-Host "=== Setting up AWS S3 Bucket for Image Upload ===" -ForegroundColor Green
Write-Host "Bucket Name: $BUCKET_NAME" -ForegroundColor Yellow
Write-Host "Region: $AWS_REGION" -ForegroundColor Yellow

# Create S3 bucket
Write-Host "Creating S3 bucket..." -ForegroundColor Blue
aws s3api create-bucket --bucket $BUCKET_NAME --region $AWS_REGION

# Enable versioning
Write-Host "Enabling versioning..." -ForegroundColor Blue
aws s3api put-bucket-versioning --bucket $BUCKET_NAME --versioning-configuration Status=Enabled

# Configure public access settings
Write-Host "Configuring bucket public access..." -ForegroundColor Blue
aws s3api put-public-access-block --bucket $BUCKET_NAME --public-access-block-configuration "BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false"

# Create bucket policy
Write-Host "Creating bucket policy..." -ForegroundColor Blue
$bucketPolicy = @"
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
"@

$bucketPolicy | Out-File -FilePath "bucket-policy.json" -Encoding UTF8
aws s3api put-bucket-policy --bucket $BUCKET_NAME --policy file://bucket-policy.json

# Configure CORS
Write-Host "Configuring CORS..." -ForegroundColor Blue
$corsConfig = @"
{
    "CORSRules": [
        {
            "AllowedOrigins": ["*"],
            "AllowedMethods": ["GET", "PUT", "POST", "DELETE"],
            "AllowedHeaders": ["*"],
            "MaxAgeSeconds": 3000
        }
    ]
}
"@

$corsConfig | Out-File -FilePath "cors-config.json" -Encoding UTF8
aws s3api put-bucket-cors --bucket $BUCKET_NAME --cors-configuration file://cors-config.json

# Create IAM policy
Write-Host "Creating IAM policy..." -ForegroundColor Blue
$iamPolicy = @"
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:PutObject",
                "s3:DeleteObject"
            ],
            "Resource": "arn:aws:s3:::$BUCKET_NAME/images/*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket"
            ],
            "Resource": "arn:aws:s3:::$BUCKET_NAME",
            "Condition": {
                "StringLike": {
                    "s3:prefix": "images/*"
                }
            }
        }
    ]
}
"@

$iamPolicy | Out-File -FilePath "s3-policy.json" -Encoding UTF8
aws iam create-policy --policy-name $POLICY_NAME --policy-document file://s3-policy.json --description "Policy for image uploader S3 access"

# Create IAM user
Write-Host "Creating IAM user..." -ForegroundColor Blue
aws iam create-user --user-name $USER_NAME

# Get policy ARN
$POLICY_ARN = aws iam list-policies --query "Policies[?PolicyName=='$POLICY_NAME'].Arn" --output text

# Attach policy to user
Write-Host "Attaching policy to user..." -ForegroundColor Blue
aws iam attach-user-policy --user-name $USER_NAME --policy-arn $POLICY_ARN

# Create access keys
Write-Host "Creating access keys..." -ForegroundColor Blue
$ACCESS_KEY_OUTPUT = aws iam create-access-key --user-name $USER_NAME --output json | ConvertFrom-Json
$ACCESS_KEY_ID = $ACCESS_KEY_OUTPUT.AccessKey.AccessKeyId
$SECRET_ACCESS_KEY = $ACCESS_KEY_OUTPUT.AccessKey.SecretAccessKey

# Clean up temporary files
Remove-Item "bucket-policy.json", "cors-config.json", "s3-policy.json" -ErrorAction SilentlyContinue

Write-Host "========================================" -ForegroundColor Green
Write-Host "S3 Setup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Bucket Name: $BUCKET_NAME" -ForegroundColor Yellow
Write-Host "Region: $AWS_REGION" -ForegroundColor Yellow
Write-Host "Bucket URL: https://$BUCKET_NAME.s3.$AWS_REGION.amazonaws.com" -ForegroundColor Yellow
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "AWS Credentials for Application:" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host "AWS_ACCESS_KEY_ID=$ACCESS_KEY_ID" -ForegroundColor Cyan
Write-Host "AWS_SECRET_ACCESS_KEY=$SECRET_ACCESS_KEY" -ForegroundColor Cyan
Write-Host "AWS_REGION=$AWS_REGION" -ForegroundColor Cyan
Write-Host "AWS_S3_BUCKET_NAME=$BUCKET_NAME" -ForegroundColor Cyan

# Save to file for later use
$credentialsText = @"
AWS_ACCESS_KEY_ID=$ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY=$SECRET_ACCESS_KEY
AWS_REGION=$AWS_REGION
AWS_S3_BUCKET_NAME=$BUCKET_NAME
"@

$credentialsText | Out-File -FilePath "aws-credentials.txt" -Encoding UTF8
Write-Host ""
Write-Host "Credentials saved to aws-credentials.txt" -ForegroundColor Green
Write-Host "Keep this file secure and don't commit to version control!" -ForegroundColor Red