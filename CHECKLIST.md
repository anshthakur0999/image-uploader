# Deployment Checklist

Use this checklist to ensure all steps are completed for successful deployment.

## Pre-Deployment Setup

### AWS Configuration
- [ ] AWS account created
- [ ] S3 bucket created
  - Bucket name: ________________
  - Region: ________________
- [ ] S3 CORS configured (`aws s3api put-bucket-cors --bucket YOUR_BUCKET --cors-configuration file://s3-cors.json`)
- [ ] IAM user created (`image-uploader-s3-user`)
- [ ] IAM user has S3 permissions (PutObject, GetObject, DeleteObject, ListBucket)
- [ ] Access Key ID saved: ________________
- [ ] Secret Access Key saved (keep secure!)

### EC2 Instance Setup
- [ ] EC2 instance launched
  - Instance type: t3.medium
  - AMI: Ubuntu 22.04 LTS
  - Storage: 30 GB
  - Instance ID: ________________
  - Public IP: ________________
- [ ] Security group configured:
  - [ ] Port 22 (SSH) - Your IP
  - [ ] Port 80 (HTTP) - 0.0.0.0/0
  - [ ] Port 443 (HTTPS) - 0.0.0.0/0
  - [ ] Port 8080 (Jenkins) - Your IP
  - [ ] Port 30080 (K3s NodePort) - 0.0.0.0/0
  - [ ] Port 6443 (K3s API) - Your IP
- [ ] SSH key pair downloaded: ________________.pem
- [ ] Can SSH into instance: `ssh -i key.pem ubuntu@IP`

### External Services
- [ ] Docker Hub account created
  - Username: ________________
- [ ] GitHub account with repository
  - Repository URL: ________________

## Server Installation

### System Setup
- [ ] Connected to EC2 instance
- [ ] System updated: `sudo apt update && sudo apt upgrade -y`
- [ ] Essential tools installed: `sudo apt install -y curl wget git vim`

### Docker Installation
- [ ] Docker installed: `curl -fsSL https://get.docker.com -o get-docker.sh && sudo sh get-docker.sh`
- [ ] User added to docker group: `sudo usermod -aG docker ubuntu`
- [ ] Docker working: `docker ps` (after logout/login)

### K3s Installation
- [ ] K3s installed: `curl -sfL https://get.k3s.io | sh -`
- [ ] K3s running: `sudo systemctl status k3s`
- [ ] kubectl configured: `mkdir -p ~/.kube && sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config`
- [ ] kubectl working: `kubectl get nodes`

### Jenkins Installation
- [ ] Java installed: `sudo apt install -y openjdk-17-jre openjdk-17-jdk`
- [ ] Jenkins repository added
- [ ] Jenkins installed: `sudo apt install -y jenkins`
- [ ] Jenkins running: `sudo systemctl status jenkins`
- [ ] Jenkins user added to docker group: `sudo usermod -aG docker jenkins`
- [ ] Jenkins restarted: `sudo systemctl restart jenkins`
- [ ] Initial admin password retrieved: `sudo cat /var/lib/jenkins/secrets/initialAdminPassword`
  - Password: ________________

**OR Use automated script:**
- [ ] Uploaded `scripts/setup-server.sh` to EC2
- [ ] Made executable: `chmod +x setup-server.sh`
- [ ] Ran script: `./setup-server.sh`
- [ ] Logged out and back in for group changes

## Jenkins Configuration

### Initial Setup
- [ ] Accessed Jenkins: http://EC2-IP:8080
- [ ] Entered initial admin password
- [ ] Installed suggested plugins
- [ ] Created admin user
  - Username: ________________
  - Password: ________________ (keep secure!)

### Plugin Installation
- [ ] Docker Pipeline plugin installed
- [ ] Kubernetes CLI plugin installed
- [ ] Git plugin installed (usually pre-installed)
- [ ] Pipeline plugin installed (usually pre-installed)
- [ ] Credentials Binding plugin installed

### Credentials Setup
- [ ] Docker Hub credentials added
  - Kind: Username with password
  - ID: `dockerhub-credentials`
  - Username: YOUR_DOCKERHUB_USERNAME
  - Password: YOUR_DOCKERHUB_PASSWORD
- [ ] Kubeconfig added
  - Kind: Secret file
  - ID: `kubeconfig`
  - File: ~/.kube/config from EC2
- [ ] GitHub credentials added (if private repo)
  - Kind: Username with password or SSH key
  - ID: `github-credentials`

### Pipeline Job Creation
- [ ] New item created
- [ ] Name: `image-uploader-pipeline`
- [ ] Type: Pipeline
- [ ] Pipeline configuration:
  - [ ] Definition: Pipeline script from SCM
  - [ ] SCM: Git
  - [ ] Repository URL: YOUR_GITHUB_REPO
  - [ ] Credentials: github-credentials (if needed)
  - [ ] Branch: */main (or */master)
  - [ ] Script Path: Jenkinsfile

## Application Configuration

### Code Updates
- [ ] Cloned repository locally
- [ ] Installed dependencies: `npm install`
- [ ] Updated `k8s/00-namespace-secrets.yaml`:
  - [ ] AWS_REGION: ________________
  - [ ] AWS_ACCESS_KEY_ID: ________________
  - [ ] AWS_SECRET_ACCESS_KEY: ________________
  - [ ] AWS_S3_BUCKET_NAME: ________________
- [ ] Updated `k8s/01-deployment.yaml`:
  - [ ] Docker image: YOUR_DOCKERHUB_USERNAME/image-uploader:latest
- [ ] Updated `Jenkinsfile`:
  - [ ] DOCKER_IMAGE_NAME: YOUR_DOCKERHUB_USERNAME/image-uploader
- [ ] Created `.env` file for local testing (from `.env.example`)
- [ ] Scripts made executable: `chmod +x scripts/*.sh`

### Local Testing (Optional)
- [ ] Application runs locally: `npm run dev`
- [ ] Can access at http://localhost:3000
- [ ] Can upload images
- [ ] Images appear in S3 bucket

### Docker Testing (Optional)
- [ ] Docker image builds: `docker build -t test:latest .`
- [ ] Docker container runs with env vars
- [ ] Application accessible in container

## Deployment

### Initial Deployment

**Option 1: Jenkins Pipeline (Recommended)**
- [ ] Code committed and pushed to GitHub
- [ ] Triggered build from Jenkins UI
- [ ] Build completed successfully
- [ ] Docker image pushed to Docker Hub
- [ ] Kubernetes deployment successful

**Option 2: Quick Deploy Script**
- [ ] Uploaded scripts to EC2
- [ ] Ran: `./scripts/deploy.sh`
- [ ] Entered required information
- [ ] Deployment completed

**Option 3: Manual Deployment**
- [ ] Built Docker image: `docker build -t USERNAME/image-uploader:latest .`
- [ ] Logged into Docker Hub: `docker login`
- [ ] Pushed image: `docker push USERNAME/image-uploader:latest`
- [ ] Applied K8s manifests: `kubectl apply -f k8s/`

### Verification
- [ ] Pods are running: `kubectl get pods -n image-uploader`
- [ ] Services are running: `kubectl get svc -n image-uploader`
- [ ] No errors in logs: `kubectl logs -f deployment/image-uploader -n image-uploader`
- [ ] Application accessible: http://EC2-PUBLIC-IP:30080
- [ ] Can upload images through UI
- [ ] Images appear in grid
- [ ] Images stored in S3 bucket

## Post-Deployment

### Testing
- [ ] Upload multiple images
- [ ] Verify images in S3
- [ ] Check pod logs for errors
- [ ] Test from different browsers
- [ ] Test from mobile device

### Monitoring
- [ ] Set up CloudWatch (optional)
- [ ] Configure log aggregation (optional)
- [ ] Set up alerts (optional)

### Documentation
- [ ] Updated README with your specifics
- [ ] Documented any custom changes
- [ ] Saved all credentials securely (password manager)

### Backup
- [ ] Backed up Kubernetes configs
- [ ] Backed up Jenkins configuration
- [ ] Documented EC2 instance configuration
- [ ] Noted all AWS resources created

## Troubleshooting (If Issues)

If deployment fails, check:
- [ ] TROUBLESHOOTING.md for common issues
- [ ] Pod status: `kubectl describe pod POD_NAME -n image-uploader`
- [ ] Pod logs: `kubectl logs POD_NAME -n image-uploader`
- [ ] Events: `kubectl get events -n image-uploader --sort-by='.lastTimestamp'`
- [ ] Service endpoints: `kubectl get endpoints -n image-uploader`
- [ ] Security group rules on EC2
- [ ] AWS credentials in secrets
- [ ] Docker Hub credentials in Jenkins
- [ ] Jenkins logs: `sudo tail -f /var/log/jenkins/jenkins.log`

## Optional Enhancements

### Production Readiness
- [ ] Set up domain name
- [ ] Configure HTTPS/SSL
  - [ ] Install cert-manager
  - [ ] Create ClusterIssuer
  - [ ] Update ingress with TLS
- [ ] Install Ingress Controller
- [ ] Set up monitoring (Prometheus + Grafana)
- [ ] Configure logging (ELK Stack)
- [ ] Set up automated backups
- [ ] Implement disaster recovery plan

### Application Enhancements
- [ ] Add user authentication
- [ ] Implement image thumbnails
- [ ] Add image metadata/tags
- [ ] Optimize images before upload
- [ ] Add image compression
- [ ] Implement CDN (CloudFront)

### CI/CD Enhancements
- [ ] Add automated tests
- [ ] Add code quality checks
- [ ] Add security scanning
- [ ] Set up staging environment
- [ ] Configure blue-green deployments

## Security Review

- [ ] AWS credentials secured (not in code)
- [ ] Kubernetes secrets used for sensitive data
- [ ] Jenkins authentication enabled
- [ ] SSH keys secured
- [ ] Security groups properly configured
- [ ] S3 bucket permissions reviewed
- [ ] IAM policies follow least privilege
- [ ] HTTPS configured (for production)
- [ ] Regular security updates scheduled

## Cost Monitoring

- [ ] AWS Cost Explorer enabled
- [ ] Billing alerts set up
- [ ] Resource usage monitored
- [ ] Considered cost optimization strategies

## Final Verification

- [ ] Application fully functional
- [ ] CI/CD pipeline working
- [ ] Can upload images via UI
- [ ] Images stored in S3
- [ ] Images displayed in grid
- [ ] Deployment scales properly
- [ ] Rollback works
- [ ] Monitoring in place
- [ ] Documentation complete
- [ ] Team members trained (if applicable)

---

## Quick Commands Reference

```bash
# Check deployment
kubectl get all -n image-uploader

# View logs
kubectl logs -f deployment/image-uploader -n image-uploader

# Scale
kubectl scale deployment/image-uploader --replicas=3 -n image-uploader

# Update
kubectl set image deployment/image-uploader image-uploader=USERNAME/image-uploader:v2 -n image-uploader

# Rollback
kubectl rollout undo deployment/image-uploader -n image-uploader

# Restart
kubectl rollout restart deployment/image-uploader -n image-uploader
```

---

**Congratulations on completing your CI/CD deployment! 🎉**

Keep this checklist for future reference and deployments.
