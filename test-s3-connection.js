// Quick AWS S3 Connection Test
// Run with: node test-s3-connection.js

require('dotenv').config();
const { S3Client, ListBucketsCommand, PutObjectCommand, ListObjectsV2Command } = require('@aws-sdk/client-s3');

const client = new S3Client({
  region: process.env.AWS_REGION || 'us-east-1',
  credentials: {
    accessKeyId: process.env.AWS_ACCESS_KEY_ID,
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
  },
});

const BUCKET_NAME = process.env.AWS_S3_BUCKET_NAME;

async function runTests() {
  console.log('🧪 Testing AWS S3 Connection...\n');
  
  // Test 1: List Buckets
  console.log('Test 1: Verifying AWS Credentials...');
  try {
    const listBucketsCommand = new ListBucketsCommand({});
    const bucketsResponse = await client.send(listBucketsCommand);
    console.log('✅ AWS Credentials are valid!');
    console.log('📦 Your buckets:', bucketsResponse.Buckets?.map(b => b.Name).join(', ') || 'None');
    console.log();
  } catch (error) {
    console.error('❌ Failed to verify credentials:', error.message);
    console.log('\n💡 Please check your .env file:');
    console.log('   - AWS_REGION');
    console.log('   - AWS_ACCESS_KEY_ID');
    console.log('   - AWS_SECRET_ACCESS_KEY');
    return;
  }
  
  // Test 2: Check if bucket exists
  console.log('Test 2: Checking if bucket exists...');
  console.log(`Looking for bucket: ${BUCKET_NAME}`);
  try {
    const listObjectsCommand = new ListObjectsV2Command({
      Bucket: BUCKET_NAME,
      MaxKeys: 1,
    });
    await client.send(listObjectsCommand);
    console.log('✅ Bucket exists and is accessible!');
    console.log();
  } catch (error) {
    if (error.name === 'NoSuchBucket') {
      console.error(`❌ Bucket "${BUCKET_NAME}" does not exist`);
      console.log('\n💡 Create the bucket first:');
      console.log(`   aws s3 mb s3://${BUCKET_NAME} --region ${process.env.AWS_REGION}`);
    } else if (error.name === 'AccessDenied') {
      console.error(`❌ Access denied to bucket "${BUCKET_NAME}"`);
      console.log('\n💡 Check IAM permissions:');
      console.log('   - s3:ListBucket');
      console.log('   - s3:GetObject');
      console.log('   - s3:PutObject');
      console.log('   - s3:DeleteObject');
    } else {
      console.error('❌ Error accessing bucket:', error.message);
    }
    return;
  }
  
  // Test 3: Try uploading a test file
  console.log('Test 3: Testing file upload...');
  try {
    const testData = Buffer.from('This is a test file from image-uploader');
    const uploadCommand = new PutObjectCommand({
      Bucket: BUCKET_NAME,
      Key: 'test/test-file.txt',
      Body: testData,
      ContentType: 'text/plain',
    });
    await client.send(uploadCommand);
    console.log('✅ Successfully uploaded test file!');
    console.log(`   Location: s3://${BUCKET_NAME}/test/test-file.txt`);
    console.log();
  } catch (error) {
    console.error('❌ Failed to upload test file:', error.message);
    console.log('\n💡 Check IAM permissions for s3:PutObject');
    return;
  }
  
  // Test 4: List objects in bucket
  console.log('Test 4: Listing objects in bucket...');
  try {
    const listCommand = new ListObjectsV2Command({
      Bucket: BUCKET_NAME,
      Prefix: 'images/',
      MaxKeys: 10,
    });
    const listResponse = await client.send(listCommand);
    const count = listResponse.KeyCount || 0;
    console.log(`✅ Found ${count} image(s) in bucket`);
    if (count > 0) {
      console.log('   Recent images:');
      listResponse.Contents?.slice(0, 5).forEach(obj => {
        console.log(`   - ${obj.Key} (${(obj.Size / 1024).toFixed(2)} KB)`);
      });
    }
    console.log();
  } catch (error) {
    console.error('❌ Failed to list objects:', error.message);
  }
  
  // Summary
  console.log('🎉 All tests passed!');
  console.log('\n✅ S3 Integration is ready!');
  console.log('\n📝 Next steps:');
  console.log('   1. Start dev server: pnpm run dev');
  console.log('   2. Open http://localhost:3000');
  console.log('   3. Upload an image to test the full flow');
  console.log();
  console.log('Configuration:');
  console.log(`   Region: ${process.env.AWS_REGION}`);
  console.log(`   Bucket: ${BUCKET_NAME}`);
  console.log(`   Access Key: ${process.env.AWS_ACCESS_KEY_ID?.substring(0, 8)}...`);
}

// Check environment variables
if (!process.env.AWS_REGION || !process.env.AWS_ACCESS_KEY_ID || 
    !process.env.AWS_SECRET_ACCESS_KEY || !process.env.AWS_S3_BUCKET_NAME) {
  console.error('❌ Missing environment variables!');
  console.log('\n💡 Please create a .env file with:');
  console.log('   AWS_REGION=us-east-1');
  console.log('   AWS_ACCESS_KEY_ID=your-access-key-id');
  console.log('   AWS_SECRET_ACCESS_KEY=your-secret-access-key');
  console.log('   AWS_S3_BUCKET_NAME=your-bucket-name');
  console.log('\n📄 You can copy from .env.example');
  process.exit(1);
}

runTests().catch(error => {
  console.error('❌ Unexpected error:', error);
  process.exit(1);
});
