# AWS EC2 Deployment Guide

Complete step-by-step guide to deploy your Image Uploader application on AWS EC2 with K3s and Jenkins.

## 📋 Overview

This guide will help you:
1. Launch an EC2 instance
2. Install K3s (lightweight Kubernetes)
3. Set up Docker and Amazon ECR
4. Install and configure Jenkins
5. Deploy your application
6. Set up CI/CD pipeline

**Estimated Time:** 90-120 minutes  
**Estimated Cost:** ~$30-40/month

---

## Part 1: Launch EC2 Instance

### Step 1.1: Navigate to EC2

1. Open AWS Console: https://console.aws.amazon.com/ec2/
2. Make sure you're in **us-east-1** region (top-right corner)
3. Click **"Launch Instance"** button

### Step 1.2: Configure Instance

**Name and Tags:**
- Name: `image-uploader-server`

**Application and OS Images (AMI):**
- Select: **Ubuntu Server 22.04 LTS**
- Architecture: **64-bit (x86)**

**Instance Type:**
- Select: **t3.medium** (2 vCPU, 4 GB RAM)
  - This is required for Jenkins + K3s
  - Costs ~$30/month

**Key Pair (Login):**
- Click **"Create new key pair"**
- Key pair name: `image-uploader-key`
- Key pair type: **RSA**
- Private key format: **PEM** (for Mac/Linux) or **PPK** (for PuTTY on Windows)
- Click **"Create key pair"**
- Save the downloaded file to a secure location (e.g., `C:\Users\Ansh\.ssh\image-uploader-key.pem`)

**Network Settings:**
- Click **"Edit"**
- VPC: Keep default
- Subnet: Keep default
- Auto-assign public IP: **Enable**

**Firewall (Security Groups):**
- Create new security group
- Security group name: `image-uploader-sg`
- Description: `Security group for image uploader with K3s and Jenkins`

Add these rules:
1. **SSH** (Port 22) - Source: My IP (for secure access)
2. **HTTP** (Port 80) - Source: Anywhere (0.0.0.0/0)
3. **HTTPS** (Port 443) - Source: Anywhere (0.0.0.0/0)
4. **Custom TCP** (Port 8080) - Source: My IP (Jenkins UI)
5. **Custom TCP** (Port 30080) - Source: Anywhere (K3s NodePort)

**Configure Storage:**
- Size: **30 GB** (increase from default 8 GB)
- Volume type: **gp3** (General Purpose SSD)
- Delete on termination: **Yes**

### Step 1.3: Create IAM Role for EC2

Before launching, let's create an IAM role:

1. Open new tab: https://console.aws.amazon.com/iam/
2. Click **"Roles"** in left sidebar
3. Click **"Create role"**
4. Select: **AWS service**
5. Use case: **EC2**
6. Click **"Next"**
7. Search and select these policies:
   - `AmazonEC2ContainerRegistryFullAccess`
   - `AmazonS3FullAccess`
8. Click **"Next"**
9. Role name: `image-uploader-ec2-role`
10. Click **"Create role"**

Go back to EC2 Launch tab:

**Advanced Details:**
- Scroll down to **IAM instance profile**
- Select: `image-uploader-ec2-role`

### Step 1.4: Launch Instance

1. Review your configuration
2. Click **"Launch instance"**
3. Wait for instance to start (2-3 minutes)
4. Click on your instance ID
5. **Copy your Public IPv4 address:** ________________

---

## Part 2: Connect to EC2 Instance

### For Windows (PowerShell):

```powershell
# Set correct permissions on key file
icacls C:\Users\Ansh\.ssh\image-uploader-key.pem /inheritance:r
icacls C:\Users\Ansh\.ssh\image-uploader-key.pem /grant:r "$env:USERNAME:(R)"

# Connect via SSH (replace with your EC2 public IP)
ssh -i C:\Users\Ansh\.ssh\image-uploader-key.pem ubuntu@YOUR_EC2_PUBLIC_IP
```

### For Mac/Linux:

```bash
# Set correct permissions on key file
chmod 400 ~/path/to/image-uploader-key.pem

# Connect via SSH (replace with your EC2 public IP)
ssh -i ~/path/to/image-uploader-key.pem ubuntu@YOUR_EC2_PUBLIC_IP
```

**First time connection:**
- Type `yes` when asked about fingerprint
- You should see Ubuntu welcome message

---

## Part 3: Upload Setup Script to EC2

Before running commands on EC2, let's upload our setup script.

### On Your Local Machine (PowerShell):

```powershell
# Navigate to your project
cd C:\Users\Ansh\Desktop\image-uploader

# Upload the setup script (replace with your EC2 IP)
scp -i C:\Users\Ansh\.ssh\image-uploader-key.pem scripts/setup-server.sh ubuntu@YOUR_EC2_PUBLIC_IP:~/
```

---

## Part 4: Install K3s and Docker on EC2

### On EC2 Instance:

```bash
# Make the script executable
chmod +x setup-server.sh

# Run the setup script
sudo ./setup-server.sh

# This will install:
# - Docker
# - K3s (lightweight Kubernetes)
# - kubectl (Kubernetes CLI)
# - Required dependencies

# This takes about 10-15 minutes
```

### Verify Installation:

```bash
# Check Docker
docker --version
# Should show: Docker version 24.x.x

# Check K3s
sudo systemctl status k3s
# Should show: active (running)

# Check kubectl
kubectl version --short
# Should show client and server versions

# View cluster
kubectl get nodes
# Should show your node in Ready state
```

---

## Part 5: Set Up Amazon ECR (Container Registry)

### On Your Local Machine (AWS Console):

1. Go to ECR: https://console.aws.amazon.com/ecr/
2. Click **"Create repository"**
3. Repository name: `image-uploader`
4. Leave other settings as default
5. Click **"Create repository"**
6. **Copy the Repository URI:** ________________
   - Example: `123456789012.dkr.ecr.us-east-1.amazonaws.com/image-uploader`

### On EC2 Instance:

```bash
# Login to ECR (replace region if different)
aws ecr get-login-password --region us-east-1 | sudo docker login --username AWS --password-stdin 123456789012.dkr.ecr.us-east-1.amazonaws.com

# You should see: Login Succeeded
```

---

## Part 6: Build and Push Docker Image

### On Your Local Machine:

```powershell
# Navigate to project
cd C:\Users\Ansh\Desktop\image-uploader

# Build the Docker image (replace with your ECR URI)
docker build -t image-uploader .

# Tag the image for ECR
docker tag image-uploader:latest 123456789012.dkr.ecr.us-east-1.amazonaws.com/image-uploader:latest

# Login to ECR from local machine
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 123456789012.dkr.ecr.us-east-1.amazonaws.com

# Push to ECR
docker push 123456789012.dkr.ecr.us-east-1.amazonaws.com/image-uploader:latest
```

**Note:** This will take 10-20 minutes depending on your upload speed.

---

## Part 7: Deploy to Kubernetes (K3s)

### Step 7.1: Upload Kubernetes Manifests to EC2

On your local machine:

```powershell
# Upload all k8s files
scp -i C:\Users\Ansh\.ssh\image-uploader-key.pem -r k8s ubuntu@YOUR_EC2_PUBLIC_IP:~/
```

### Step 7.2: Update Kubernetes Secrets

On EC2:

```bash
# Edit the secrets file
nano ~/k8s/secrets.yaml
```

Update with your actual AWS credentials:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: image-uploader-secrets
  namespace: image-uploader
type: Opaque
stringData:
  AWS_REGION: "us-east-1"
  AWS_ACCESS_KEY_ID: "YOUR_ACTUAL_ACCESS_KEY"
  AWS_SECRET_ACCESS_KEY: "YOUR_ACTUAL_SECRET_KEY"
  AWS_S3_BUCKET_NAME: "image-uploader-yourname-20251004"
  NEXT_PUBLIC_API_URL: "http://YOUR_EC2_PUBLIC_IP:30080"
```

Save: `Ctrl+X`, then `Y`, then `Enter`

### Step 7.3: Update Deployment Image

```bash
# Edit deployment
nano ~/k8s/deployment.yaml
```

Find the `image:` line and replace with your ECR image URI:

```yaml
image: 123456789012.dkr.ecr.us-east-1.amazonaws.com/image-uploader:latest
```

Save: `Ctrl+X`, then `Y`, then `Enter`

### Step 7.4: Apply Kubernetes Manifests

```bash
# Apply all manifests
kubectl apply -f ~/k8s/namespace.yaml
kubectl apply -f ~/k8s/secrets.yaml
kubectl apply -f ~/k8s/deployment.yaml
kubectl apply -f ~/k8s/service.yaml

# Wait for pods to be ready
kubectl get pods -n image-uploader -w
# Press Ctrl+C when you see "Running" status

# Check deployment
kubectl get all -n image-uploader
```

---

## Part 8: Access Your Application

Your application is now running!

**Access URL:** `http://YOUR_EC2_PUBLIC_IP:30080`

Test:
1. Upload an image
2. Check it appears in the gallery
3. Try deleting an image
4. Verify images are in S3

---

## Part 9: Install Jenkins (CI/CD)

### On EC2 Instance:

```bash
# Install Java (required for Jenkins)
sudo apt update
sudo apt install -y openjdk-11-jdk

# Add Jenkins repository
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo tee \
  /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null

# Install Jenkins
sudo apt update
sudo apt install -y jenkins

# Start Jenkins
sudo systemctl start jenkins
sudo systemctl enable jenkins

# Get initial admin password
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
# Copy this password: ________________
```

### Access Jenkins:

1. Open browser: `http://YOUR_EC2_PUBLIC_IP:8080`
2. Paste the initial admin password
3. Click **"Install suggested plugins"**
4. Create admin user:
   - Username: `admin`
   - Password: (choose secure password)
   - Email: your email
5. Click **"Save and Continue"**
6. Jenkins URL: Keep default
7. Click **"Start using Jenkins"**

---

## Part 10: Configure Jenkins Pipeline

### Step 10.1: Install Required Plugins

1. Click **"Manage Jenkins"** → **"Plugins"**
2. Click **"Available plugins"**
3. Search and install:
   - Docker Pipeline
   - Kubernetes CLI Plugin
   - Git Plugin (should already be installed)
4. Click **"Install"** and restart Jenkins if needed

### Step 10.2: Add Credentials

1. Click **"Manage Jenkins"** → **"Credentials"**
2. Click **"(global)"** → **"Add Credentials"**

**Add AWS Credentials:**
- Kind: Secret text
- Secret: (your AWS_ACCESS_KEY_ID)
- ID: `aws-access-key-id`

**Add AWS Secret Key:**
- Kind: Secret text
- Secret: (your AWS_SECRET_ACCESS_KEY)
- ID: `aws-secret-access-key`

### Step 10.3: Create Pipeline Job

1. Click **"New Item"**
2. Name: `image-uploader-pipeline`
3. Select: **Pipeline**
4. Click **"OK"**

In configuration:
- Build Triggers: Check **"Poll SCM"**
  - Schedule: `H/5 * * * *` (every 5 minutes)
- Pipeline:
  - Definition: **Pipeline script from SCM**
  - SCM: **Git**
  - Repository URL: (your GitHub repo URL)
  - Branch: `*/main`
  - Script Path: `Jenkinsfile`

5. Click **"Save"**

### Step 10.4: Run Pipeline

1. Click **"Build Now"**
2. Watch the pipeline execute
3. All stages should pass: ✅

---

## Part 11: Testing & Verification

### Test the Application:

```bash
# Check pods are running
kubectl get pods -n image-uploader

# Check service
kubectl get svc -n image-uploader

# Check logs
kubectl logs -n image-uploader -l app=image-uploader --tail=50
```

### Test from Browser:

1. Go to: `http://YOUR_EC2_PUBLIC_IP:30080`
2. Upload multiple images
3. Delete an image
4. Verify images persist after refresh
5. Check S3 bucket has the files

### Test CI/CD:

1. Make a small code change locally
2. Push to GitHub
3. Jenkins should automatically:
   - Pull new code
   - Build Docker image
   - Push to ECR
   - Deploy to K3s
   - Verify deployment

---

## Part 12: Monitoring & Maintenance

### Check Application Logs:

```bash
# Real-time logs
kubectl logs -n image-uploader -l app=image-uploader -f

# Last 100 lines
kubectl logs -n image-uploader -l app=image-uploader --tail=100
```

### Check Resource Usage:

```bash
# Node resources
kubectl top nodes

# Pod resources
kubectl top pods -n image-uploader
```

### Restart Application:

```bash
# Rolling restart
kubectl rollout restart deployment/image-uploader -n image-uploader

# Check rollout status
kubectl rollout status deployment/image-uploader -n image-uploader
```

---

## 🎉 Congratulations!

Your application is now:
- ✅ Running on AWS EC2
- ✅ Containerized with Docker
- ✅ Orchestrated with Kubernetes (K3s)
- ✅ Using S3 for image storage
- ✅ Automated with Jenkins CI/CD

## 💰 Cost Breakdown

- **EC2 t3.medium:** ~$30/month
- **S3 storage:** ~$0.023/GB/month
- **ECR storage:** Free tier (500MB), then $0.10/GB/month
- **Data transfer:** First 1GB free, then $0.09/GB

**Total:** ~$30-40/month

## 🔒 Security Recommendations

1. **Restrict SSH access:** Only allow your IP in security group
2. **Use HTTPS:** Set up SSL certificate with Let's Encrypt
3. **Rotate credentials:** Change AWS keys every 90 days
4. **Enable MFA:** On AWS account and Jenkins
5. **Regular updates:** `sudo apt update && sudo apt upgrade`

## 🆘 Troubleshooting

### Application won't start:

```bash
kubectl describe pod -n image-uploader
kubectl logs -n image-uploader -l app=image-uploader
```

### Can't access from browser:

- Check security group has port 30080 open
- Check service: `kubectl get svc -n image-uploader`
- Check EC2 public IP hasn't changed

### Images not uploading:

- Verify AWS credentials in secrets
- Check S3 bucket permissions
- Check pod logs for errors

### Jenkins build fails:

- Check Jenkins credentials
- Verify ECR repository exists
- Check Jenkins has Docker permissions: `sudo usermod -aG docker jenkins`

---

## 📚 Additional Resources

- [K3s Documentation](https://docs.k3s.io/)
- [Jenkins Pipeline Syntax](https://www.jenkins.io/doc/book/pipeline/syntax/)
- [AWS ECR User Guide](https://docs.aws.amazon.com/ecr/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)

---

## Next Steps

1. Set up domain name with Route 53
2. Configure HTTPS with cert-manager
3. Set up monitoring with Prometheus/Grafana
4. Configure auto-scaling
5. Add database for metadata
6. Implement user authentication
