#!/bin/bash

# AWS S3 Bucket Setup Script
# This script creates and configures an S3 bucket for image storage

set -e

# Configuration
BUCKET_NAME="your-image-upload-bucket-$(date +%s)"  # Append timestamp for uniqueness
AWS_REGION="us-east-1"
POLICY_NAME="ImageUploaderS3Policy"
USER_NAME="image-uploader-s3-user"

echo "=== Setting up AWS S3 Bucket for Image Upload ==="
echo "Bucket Name: $BUCKET_NAME"
echo "Region: $AWS_REGION"

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "AWS CLI is not installed. Please install it first:"
    echo "https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
    exit 1
fi

# Check if AWS CLI is configured
if ! aws sts get-caller-identity &> /dev/null; then
    echo "AWS CLI is not configured. Please run 'aws configure' first."
    exit 1
fi

# Create S3 bucket
echo "Creating S3 bucket..."
if [ "$AWS_REGION" = "us-east-1" ]; then
    aws s3api create-bucket --bucket $BUCKET_NAME --region $AWS_REGION
else
    aws s3api create-bucket --bucket $BUCKET_NAME --region $AWS_REGION --create-bucket-configuration LocationConstraint=$AWS_REGION
fi

# Enable versioning
echo "Enabling versioning..."
aws s3api put-bucket-versioning --bucket $BUCKET_NAME --versioning-configuration Status=Enabled

# Configure public access settings
echo "Configuring bucket public access..."
aws s3api put-public-access-block --bucket $BUCKET_NAME --public-access-block-configuration "BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false"

# Create bucket policy for public read access to images
echo "Creating bucket policy..."
cat > /tmp/bucket-policy.json << EOF
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

aws s3api put-bucket-policy --bucket $BUCKET_NAME --policy file:///tmp/bucket-policy.json

# Configure CORS for web uploads
echo "Configuring CORS..."
cat > /tmp/cors-config.json << EOF
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
EOF

aws s3api put-bucket-cors --bucket $BUCKET_NAME --cors-configuration file:///tmp/cors-config.json

# Create lifecycle policy to manage storage costs
echo "Creating lifecycle policy..."
cat > /tmp/lifecycle-policy.json << EOF
{
    "Rules": [
        {
            "ID": "ImageStorageOptimization",
            "Status": "Enabled",
            "Filter": {"Prefix": "images/"},
            "Transitions": [
                {
                    "Days": 30,
                    "StorageClass": "STANDARD_IA"
                },
                {
                    "Days": 365,
                    "StorageClass": "GLACIER"
                }
            ],
            "NoncurrentVersionTransitions": [
                {
                    "NoncurrentDays": 30,
                    "StorageClass": "STANDARD_IA"
                }
            ],
            "NoncurrentVersionExpiration": {
                "NoncurrentDays": 365
            }
        }
    ]
}
EOF

aws s3api put-bucket-lifecycle-configuration --bucket $BUCKET_NAME --lifecycle-configuration file:///tmp/lifecycle-policy.json

# Create IAM policy for application access
echo "Creating IAM policy..."
cat > /tmp/s3-policy.json << EOF
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
EOF

aws iam create-policy --policy-name $POLICY_NAME --policy-document file:///tmp/s3-policy.json --description "Policy for image uploader S3 access"

# Create IAM user
echo "Creating IAM user..."
aws iam create-user --user-name $USER_NAME

# Get policy ARN
POLICY_ARN=$(aws iam list-policies --query "Policies[?PolicyName=='$POLICY_NAME'].Arn" --output text)

# Attach policy to user
echo "Attaching policy to user..."
aws iam attach-user-policy --user-name $USER_NAME --policy-arn $POLICY_ARN

# Create access keys
echo "Creating access keys..."
ACCESS_KEY_OUTPUT=$(aws iam create-access-key --user-name $USER_NAME --output json)
ACCESS_KEY_ID=$(echo $ACCESS_KEY_OUTPUT | jq -r '.AccessKey.AccessKeyId')
SECRET_ACCESS_KEY=$(echo $ACCESS_KEY_OUTPUT | jq -r '.AccessKey.SecretAccessKey')

# Clean up temporary files
rm -f /tmp/bucket-policy.json /tmp/cors-config.json /tmp/lifecycle-policy.json /tmp/s3-policy.json

echo "========================================"
echo "S3 Setup Complete!"
echo "========================================"
echo ""
echo "Bucket Name: $BUCKET_NAME"
echo "Region: $AWS_REGION"
echo "Bucket URL: https://$BUCKET_NAME.s3.$AWS_REGION.amazonaws.com"
echo ""
echo "========================================"
echo "AWS Credentials for Application:"
echo "========================================"
echo "AWS_ACCESS_KEY_ID=$ACCESS_KEY_ID"
echo "AWS_SECRET_ACCESS_KEY=$SECRET_ACCESS_KEY"
echo "AWS_REGION=$AWS_REGION"
echo "AWS_S3_BUCKET_NAME=$BUCKET_NAME"
echo ""
echo "========================================"
echo "Next Steps:"
echo "========================================"
echo "1. Update your .env file with the credentials above"
echo "2. Update Kubernetes secrets in k8s/00-namespace-secrets.yaml:"
echo "   - Base64 encode the credentials:"
echo "   echo -n '$ACCESS_KEY_ID' | base64"
echo "   echo -n '$SECRET_ACCESS_KEY' | base64"
echo "3. Update k8s/00-namespace-secrets.yaml with your bucket name"
echo "4. Test the connection by running your application"
echo ""
echo "Security Notes:"
echo "- Store these credentials securely"
echo "- Never commit credentials to version control"
echo "- Consider using IAM roles instead of access keys in production"
echo "- Enable CloudTrail for audit logging"
echo "- Set up monitoring and alerts for unusual access patterns"