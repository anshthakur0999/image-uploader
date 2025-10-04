pipeline {
    agent any
    
    environment {
        AWS_REGION = 'us-east-1'
        ECR_REGISTRY = '503015902469.dkr.ecr.us-east-1.amazonaws.com'
        ECR_REPOSITORY = 'image-uploader'
        AWS_ACCOUNT_ID = '503015902469'
        IMAGE_TAG = "${env.BUILD_NUMBER}"
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
                    sh "docker build -t ${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG} ."
                    sh "docker tag ${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG} ${ECR_REGISTRY}/${ECR_REPOSITORY}:latest"
                }
            }
        }
        
        stage('Push to ECR') {
            steps {
                script {
                    echo "Pushing image to Amazon ECR..."
                    withCredentials([
                        string(credentialsId: 'aws-access-key-id', variable: 'AWS_ACCESS_KEY_ID'),
                        string(credentialsId: 'aws-secret-access-key', variable: 'AWS_SECRET_ACCESS_KEY')
                    ]) {
                        sh """
                            aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}
                            docker push ${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG}
                            docker push ${ECR_REGISTRY}/${ECR_REPOSITORY}:latest
                        """
                    }
                }
            }
        }
        
        stage('Deploy to Kubernetes') {
            steps {
                script {
                    echo "Deploying to Kubernetes..."
                    withCredentials([
                        string(credentialsId: 'aws-access-key-id', variable: 'AWS_ACCESS_KEY_ID'),
                        string(credentialsId: 'aws-secret-access-key', variable: 'AWS_SECRET_ACCESS_KEY')
                    ]) {
                        // Recreate ECR credentials for K8s
                        sh """
                            kubectl delete secret ecr-credentials -n image-uploader --ignore-not-found=true
                            kubectl create secret docker-registry ecr-credentials \
                              --docker-server=${ECR_REGISTRY} \
                              --docker-username=AWS \
                              --docker-password=\$(aws ecr get-login-password --region ${AWS_REGION}) \
                              --namespace=image-uploader
                        """
                        
                        // Update deployment with new image
                        sh """
                            kubectl set image deployment/image-uploader \
                                image-uploader=${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG} \
                                -n image-uploader
                        """
                        
                        // Wait for rollout to complete
                        sh """
                            kubectl rollout status deployment/image-uploader -n image-uploader --timeout=5m
                        """
                    }
                }
            }
        }
        
        stage('Verify Deployment') {
            steps {
                script {
                    echo "Verifying deployment..."
                    sh """
                        kubectl get pods -n image-uploader
                        kubectl get services -n image-uploader
                    """
                }
            }
        }
    }
    
    post {
        success {
            echo 'Pipeline executed successfully!'
            echo "Deployed image: ${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG}"
        }
        failure {
            echo 'Pipeline failed!'
        }
        always {
            echo 'Cleaning up...'
            sh "docker rmi ${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG} || true"
            sh "docker rmi ${ECR_REGISTRY}/${ECR_REPOSITORY}:latest || true"
        }
    }
}
