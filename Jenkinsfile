pipeline {
    agent any
    
    environment {
        AWS_REGION = 'us-east-1'
        ECR_REGISTRY = '503015902469.dkr.ecr.us-east-1.amazonaws.com'
        ECR_REPOSITORY = 'image-uploader'
        IMAGE_TAG = "${BUILD_NUMBER}"
        EC2_HOST = '54.167.28.105'
        EC2_USER = 'ubuntu'
        SSH_KEY_PATH = 'C:\\Users\\Ansh\\.ssh\\image-uploader-key.pem'
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out code...'
                checkout scm
            }
        }
        
        stage('Build Docker Image') {
            steps {
                script {
                    echo "Building Docker image with tag: ${IMAGE_TAG}"
                    bat "docker build -t ${ECR_REPOSITORY}:${IMAGE_TAG} ."
                    bat "docker tag ${ECR_REPOSITORY}:${IMAGE_TAG} ${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG}"
                    bat "docker tag ${ECR_REPOSITORY}:${IMAGE_TAG} ${ECR_REGISTRY}/${ECR_REPOSITORY}:latest"
                }
            }
        }
        
        stage('Push to ECR') {
            steps {
                withCredentials([
                    string(credentialsId: 'aws-access-key-id', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'aws-secret-access-key', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    script {
                        echo 'Pushing image to Amazon ECR...'
                        bat """
                            aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}
                            docker push ${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG}
                            docker push ${ECR_REGISTRY}/${ECR_REPOSITORY}:latest
                        """
                    }
                }
            }
        }
        
        stage('Deploy to K3s') {
            steps {
                script {
                    echo 'Deploying to K3s...'
                    bat """
                        "C:\\Program Files\\Git\\usr\\bin\\ssh.exe" -i ${SSH_KEY_PATH} -o StrictHostKeyChecking=no ${EC2_USER}@${EC2_HOST} "kubectl set image deployment/image-uploader image-uploader=${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG} -n image-uploader && kubectl rollout status deployment/image-uploader -n image-uploader"
                    """
                }
            }
        }
    }
    
    post {
        always {
            echo 'Pipeline finished!'
        }
        success {
            echo 'Deployment successful!'
        }
        failure {
            echo 'Deployment failed!'
        }
    }
}
