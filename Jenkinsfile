pipeline {
    agent any
    
    environment {
        DOCKER_REGISTRY = 'docker.io'
        DOCKER_IMAGE_NAME = 'your-dockerhub-username/image-uploader'
        DOCKER_CREDENTIALS_ID = 'dockerhub-credentials'
        KUBECONFIG_CREDENTIALS_ID = 'kubeconfig'
        GIT_COMMIT_SHORT = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
        IMAGE_TAG = "${env.BUILD_NUMBER}-${GIT_COMMIT_SHORT}"
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
                    docker.build("${DOCKER_IMAGE_NAME}:${IMAGE_TAG}")
                    docker.build("${DOCKER_IMAGE_NAME}:latest")
                }
            }
        }
        
        stage('Push to Docker Registry') {
            steps {
                script {
                    echo "Pushing image to Docker Registry..."
                    docker.withRegistry("https://${DOCKER_REGISTRY}", "${DOCKER_CREDENTIALS_ID}") {
                        docker.image("${DOCKER_IMAGE_NAME}:${IMAGE_TAG}").push()
                        docker.image("${DOCKER_IMAGE_NAME}:latest").push()
                    }
                }
            }
        }
        
        stage('Deploy to Kubernetes') {
            steps {
                script {
                    echo "Deploying to Kubernetes..."
                    withCredentials([file(credentialsId: "${KUBECONFIG_CREDENTIALS_ID}", variable: 'KUBECONFIG')]) {
                        // Apply Kubernetes manifests
                        sh """
                            kubectl apply -f k8s/00-namespace-secrets.yaml
                            kubectl apply -f k8s/01-deployment.yaml
                            kubectl apply -f k8s/02-service.yaml
                            kubectl apply -f k8s/03-ingress.yaml
                        """
                        
                        // Update deployment with new image
                        sh """
                            kubectl set image deployment/image-uploader \
                                image-uploader=${DOCKER_IMAGE_NAME}:${IMAGE_TAG} \
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
                    withCredentials([file(credentialsId: "${KUBECONFIG_CREDENTIALS_ID}", variable: 'KUBECONFIG')]) {
                        sh """
                            kubectl get pods -n image-uploader
                            kubectl get services -n image-uploader
                            kubectl get ingress -n image-uploader
                        """
                    }
                }
            }
        }
    }
    
    post {
        success {
            echo 'Pipeline executed successfully!'
            echo "Deployed image: ${DOCKER_IMAGE_NAME}:${IMAGE_TAG}"
        }
        failure {
            echo 'Pipeline failed!'
        }
        always {
            echo 'Cleaning up...'
            sh "docker rmi ${DOCKER_IMAGE_NAME}:${IMAGE_TAG} || true"
            sh "docker rmi ${DOCKER_IMAGE_NAME}:latest || true"
        }
    }
}
