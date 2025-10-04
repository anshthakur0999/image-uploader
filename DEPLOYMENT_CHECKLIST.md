# 🚀 AWS Deployment Step-by-Step Checklist

Use this checklist to track your deployment progress. Check off each item as you complete it.

---

## ✅ Pre-Deployment (Already Complete!)

- [x] S3 integration implemented and tested
- [x] AWS IAM user created
- [x] S3 bucket created: `image-uploader-yourname-20251004`
- [x] Local testing successful (upload, delete working)
- [x] Images displaying properly with presigned URLs
- [x] All code committed to Git

---

## 🖥️ Part 1: EC2 Instance Setup

### Launch EC2 Instance
- [ ] Navigate to EC2 Console: https://console.aws.amazon.com/ec2/
- [ ] Click "Launch Instance"
- [ ] Name: `image-uploader-server`
- [ ] Select Ubuntu Server 22.04 LTS
- [ ] Choose t3.medium instance type
- [ ] Create key pair: `image-uploader-key` (save to `C:\Users\Ansh\.ssh\`)
- [ ] Configure security group with these ports:
  - [ ] Port 22 (SSH) - My IP only
  - [ ] Port 80 (HTTP) - 0.0.0.0/0
  - [ ] Port 443 (HTTPS) - 0.0.0.0/0
  - [ ] Port 8080 (Jenkins) - My IP only
  - [ ] Port 30080 (K3s) - 0.0.0.0/0
- [ ] Set storage to 30 GB
- [ ] Create IAM role: `image-uploader-ec2-role` with:
  - [ ] AmazonEC2ContainerRegistryFullAccess
  - [ ] AmazonS3FullAccess
- [ ] Attach IAM role to instance
- [ ] Click "Launch Instance"
- [ ] Wait for instance to be running (2-3 min)
- [ ] Copy Public IPv4 address: ____________________

### Connect to EC2
- [ ] Open PowerShell on local machine
- [ ] Set key permissions:
  ```powershell
  icacls C:\Users\Ansh\.ssh\image-uploader-key.pem /inheritance:r
  icacls C:\Users\Ansh\.ssh\image-uploader-key.pem /grant:r "$env:USERNAME:(R)"
  ```
- [ ] Connect via SSH (replace YOUR_EC2_IP):
  ```powershell
  ssh -i C:\Users\Ansh\.ssh\image-uploader-key.pem ubuntu@YOUR_EC2_IP
  ```
- [ ] Type `yes` when asked about fingerprint
- [ ] Successfully connected (see Ubuntu welcome message)

---

## 🐳 Part 2: Docker & K3s Installation

### Upload Setup Script
- [ ] From local PowerShell:
  ```powershell
  cd C:\Users\Ansh\Desktop\image-uploader
  scp -i C:\Users\Ansh\.ssh\image-uploader-key.pem scripts/setup-server.sh ubuntu@YOUR_EC2_IP:~/
  ```

### Run Setup Script (On EC2)
- [ ] Make script executable:
  ```bash
  chmod +x setup-server.sh
  ```
- [ ] Run setup:
  ```bash
  sudo ./setup-server.sh
  ```
- [ ] Wait 10-15 minutes for completion
- [ ] No errors during installation

### Verify Installation (On EC2)
- [ ] Check Docker:
  ```bash
  docker --version
  ```
- [ ] Check K3s status:
  ```bash
  sudo systemctl status k3s
  ```
- [ ] Check kubectl:
  ```bash
  kubectl version --short
  ```
- [ ] View cluster:
  ```bash
  kubectl get nodes
  ```
  Should show: `Ready` status

---

## 📦 Part 3: Amazon ECR Setup

### Create ECR Repository
- [ ] Go to ECR: https://console.aws.amazon.com/ecr/
- [ ] Click "Create repository"
- [ ] Name: `image-uploader`
- [ ] Click "Create repository"
- [ ] Copy Repository URI: ____________________
  Example: `123456789012.dkr.ecr.us-east-1.amazonaws.com/image-uploader`

### Login to ECR (On EC2)
- [ ] Run (replace with your URI):
  ```bash
  aws ecr get-login-password --region us-east-1 | sudo docker login --username AWS --password-stdin 123456789012.dkr.ecr.us-east-1.amazonaws.com
  ```
- [ ] See "Login Succeeded" message

---

## 🏗️ Part 4: Build and Push Docker Image

### From Local Machine
- [ ] Open PowerShell
- [ ] Navigate to project:
  ```powershell
  cd C:\Users\Ansh\Desktop\image-uploader
  ```
- [ ] Login to ECR:
  ```powershell
  aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin YOUR_ECR_URI
  ```
- [ ] Build image:
  ```powershell
  docker build -t image-uploader .
  ```
- [ ] Wait 5-10 minutes for build
- [ ] Tag image:
  ```powershell
  docker tag image-uploader:latest YOUR_ECR_URI/image-uploader:latest
  ```
- [ ] Push to ECR:
  ```powershell
  docker push YOUR_ECR_URI/image-uploader:latest
  ```
- [ ] Wait 10-20 minutes for push
- [ ] Verify in ECR console (should see image with `latest` tag)

---

## ☸️ Part 5: Deploy to Kubernetes

### Upload K8s Files (From Local)
- [ ] Upload manifests:
  ```powershell
  scp -i C:\Users\Ansh\.ssh\image-uploader-key.pem -r k8s ubuntu@YOUR_EC2_IP:~/
  ```

### Update Secrets (On EC2)
- [ ] Edit secrets file:
  ```bash
  nano ~/k8s/secrets.yaml
  ```
- [ ] Update with your actual values:
  - [ ] AWS_REGION: `us-east-1`
  - [ ] AWS_ACCESS_KEY_ID: `AKIAXXXXXXXXXXXXX`
  - [ ] AWS_SECRET_ACCESS_KEY: `xxxxxxxxxxxxxxxxxx`
  - [ ] AWS_S3_BUCKET_NAME: `image-uploader-yourname-20251004`
  - [ ] NEXT_PUBLIC_API_URL: `http://YOUR_EC2_PUBLIC_IP:30080`
- [ ] Save: `Ctrl+X`, `Y`, `Enter`

### Update Deployment Image (On EC2)
- [ ] Edit deployment:
  ```bash
  nano ~/k8s/deployment.yaml
  ```
- [ ] Find `image:` line (around line 20)
- [ ] Replace with your ECR URI:
  ```yaml
  image: YOUR_ECR_URI/image-uploader:latest
  ```
- [ ] Save: `Ctrl+X`, `Y`, `Enter`

### Apply Manifests (On EC2)
- [ ] Apply namespace:
  ```bash
  kubectl apply -f ~/k8s/namespace.yaml
  ```
- [ ] Apply secrets:
  ```bash
  kubectl apply -f ~/k8s/secrets.yaml
  ```
- [ ] Apply deployment:
  ```bash
  kubectl apply -f ~/k8s/deployment.yaml
  ```
- [ ] Apply service:
  ```bash
  kubectl apply -f ~/k8s/service.yaml
  ```
- [ ] Watch pods start:
  ```bash
  kubectl get pods -n image-uploader -w
  ```
- [ ] Wait until status shows `Running` (press `Ctrl+C` after)
- [ ] All 2 pods running successfully

---

## 🧪 Part 6: Test Deployment

### Access Application
- [ ] Open browser to: `http://YOUR_EC2_PUBLIC_IP:30080`
- [ ] Application loads successfully
- [ ] No errors in browser console (F12)

### Test Functionality
- [ ] Upload a test image
- [ ] Image appears in gallery
- [ ] Image displays properly (not just icon)
- [ ] Delete the image
- [ ] Image removed from gallery
- [ ] Verify in S3 that image is deleted
- [ ] Upload multiple images
- [ ] All images display correctly

### Check Logs (On EC2)
- [ ] View pod logs:
  ```bash
  kubectl logs -n image-uploader -l app=image-uploader --tail=50
  ```
- [ ] No error messages in logs

---

## 🔧 Part 7: Install Jenkins (Optional but Recommended)

### Install Jenkins (On EC2)
- [ ] Install Java:
  ```bash
  sudo apt update
  sudo apt install -y openjdk-11-jdk
  ```
- [ ] Add Jenkins repository and install:
  ```bash
  curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
  echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
  sudo apt update
  sudo apt install -y jenkins
  ```
- [ ] Start Jenkins:
  ```bash
  sudo systemctl start jenkins
  sudo systemctl enable jenkins
  ```
- [ ] Get initial password:
  ```bash
  sudo cat /var/lib/jenkins/secrets/initialAdminPassword
  ```
- [ ] Copy password: ____________________

### Configure Jenkins
- [ ] Open browser: `http://YOUR_EC2_IP:8080`
- [ ] Paste initial admin password
- [ ] Click "Install suggested plugins"
- [ ] Wait for plugins to install
- [ ] Create admin user:
  - [ ] Username: `admin`
  - [ ] Password: (choose secure password)
  - [ ] Email: your email
- [ ] Click "Save and Continue"
- [ ] Keep Jenkins URL as default
- [ ] Click "Start using Jenkins"

### Install Required Plugins
- [ ] Click "Manage Jenkins" → "Plugins"
- [ ] Click "Available plugins"
- [ ] Search and install:
  - [ ] Docker Pipeline
  - [ ] Kubernetes CLI Plugin
- [ ] Restart Jenkins if prompted

### Add Credentials
- [ ] Click "Manage Jenkins" → "Credentials"
- [ ] Click "(global)" → "Add Credentials"
- [ ] Add AWS Access Key:
  - [ ] Kind: Secret text
  - [ ] Secret: (your AWS_ACCESS_KEY_ID)
  - [ ] ID: `aws-access-key-id`
- [ ] Add AWS Secret Key:
  - [ ] Kind: Secret text
  - [ ] Secret: (your AWS_SECRET_ACCESS_KEY)
  - [ ] ID: `aws-secret-access-key`

### Create Pipeline Job
- [ ] Click "New Item"
- [ ] Name: `image-uploader-pipeline`
- [ ] Select: Pipeline
- [ ] Click "OK"
- [ ] Configure:
  - [ ] Build Triggers: Poll SCM
  - [ ] Schedule: `H/5 * * * *`
  - [ ] Pipeline Definition: Pipeline script from SCM
  - [ ] SCM: Git
  - [ ] Repository URL: (your GitHub repo)
  - [ ] Branch: `*/main`
  - [ ] Script Path: `Jenkinsfile`
- [ ] Click "Save"

### Test Pipeline
- [ ] Click "Build Now"
- [ ] Watch pipeline execute
- [ ] All stages pass: ✅

---

## 🎉 Part 8: Final Verification

### Application Health
- [ ] Application accessible at `http://YOUR_EC2_IP:30080`
- [ ] Upload works
- [ ] Delete works
- [ ] Images display properly
- [ ] Images persist after browser refresh
- [ ] Multiple concurrent uploads work

### Infrastructure Health
- [ ] Pods running: `kubectl get pods -n image-uploader`
- [ ] Service active: `kubectl get svc -n image-uploader`
- [ ] K3s healthy: `kubectl get nodes`
- [ ] Docker running: `docker ps`
- [ ] Jenkins accessible: `http://YOUR_EC2_IP:8080`

### AWS Resources
- [ ] S3 bucket has uploaded images
- [ ] ECR repository has Docker image
- [ ] EC2 instance running
- [ ] Security groups configured correctly
- [ ] IAM roles attached

---

## 📝 Documentation

### Save These Values
- [ ] EC2 Public IP: ____________________
- [ ] ECR Repository URI: ____________________
- [ ] S3 Bucket Name: ____________________
- [ ] Jenkins Admin Password: ____________________ (keep secure!)
- [ ] Application URL: `http://YOUR_EC2_IP:30080`
- [ ] Jenkins URL: `http://YOUR_EC2_IP:8080`

### Bookmark These
- [ ] Application: `http://YOUR_EC2_IP:30080`
- [ ] Jenkins: `http://YOUR_EC2_IP:8080`
- [ ] AWS Console: https://console.aws.amazon.com
- [ ] ECR: https://console.aws.amazon.com/ecr/
- [ ] S3: https://console.aws.amazon.com/s3/

---

## 🎊 Congratulations!

If all items are checked, you have successfully:
- ✅ Deployed application to AWS EC2
- ✅ Running on Kubernetes (K3s)
- ✅ Using S3 for image storage
- ✅ Containerized with Docker
- ✅ Automated with Jenkins CI/CD
- ✅ Production-ready infrastructure

---

## 📚 Next Steps (Optional Enhancements)

- [ ] Set up custom domain name with Route 53
- [ ] Configure HTTPS with Let's Encrypt
- [ ] Set up monitoring with Prometheus/Grafana
- [ ] Implement auto-scaling
- [ ] Add database for metadata
- [ ] Implement user authentication
- [ ] Set up CloudWatch logs
- [ ] Configure automated backups

---

## 🆘 Troubleshooting

If something doesn't work:
1. Check pod logs: `kubectl logs -n image-uploader -l app=image-uploader --tail=100`
2. Check pod status: `kubectl describe pod -n image-uploader POD_NAME`
3. Verify secrets: `kubectl get secret -n image-uploader`
4. Check security groups: Ensure ports are open
5. Review AWS credentials: Make sure they're correct in secrets
6. Check S3 permissions: Verify IAM user has access
7. See QUICK_COMMANDS.md for more troubleshooting commands

---

## 💰 Monthly Cost Estimate

- EC2 t3.medium: ~$30
- S3 storage: ~$0.50 (for 20GB)
- ECR: Free tier (500MB)
- Data transfer: ~$1
- **Total: ~$31-35/month**

---

## 🔒 Security Reminders

- [ ] SSH key file is secure and backed up
- [ ] AWS credentials not committed to Git
- [ ] Security group limits SSH to your IP
- [ ] Jenkins password is strong
- [ ] Regular security updates: `sudo apt update && sudo apt upgrade`

---

Good luck with your deployment! 🚀
