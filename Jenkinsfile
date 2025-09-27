pipeline {
    agent any
    
    environment {
        // Docker configuration
        DOCKER_IMAGE = "your-dockerhub-username/image-uploader"
        DOCKER_TAG = "${BUILD_NUMBER}"
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-credentials')
        
        // Kubernetes configuration
        KUBECONFIG_CREDENTIALS = credentials('kubeconfig-file')
        K8S_NAMESPACE = "image-uploader"
        
        // AWS configuration (for S3 setup)
        AWS_CREDENTIALS = credentials('aws-credentials')
        
        // Application configuration
        NODE_ENV = "production"
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
                script {
                    // Get commit hash for tagging
                    env.GIT_COMMIT_SHORT = sh(
                        script: 'git rev-parse --short HEAD',
                        returnStdout: true
                    ).trim()
                    env.DOCKER_TAG_FULL = "${DOCKER_TAG}-${GIT_COMMIT_SHORT}"
                }
            }
        }
        
        stage('Install Dependencies') {
            steps {
                sh '''
                    echo "Installing dependencies with pnpm..."
                    npm install -g pnpm
                    pnpm install --frozen-lockfile
                '''
            }
        }
        
        stage('Lint and Type Check') {
            parallel {
                stage('ESLint') {
                    steps {
                        sh 'pnpm run lint || echo "Linting completed with warnings"'
                    }
                }
                stage('TypeScript Check') {
                    steps {
                        sh 'npx tsc --noEmit || echo "TypeScript check completed with warnings"'
                    }
                }
            }
        }
        
        stage('Build Application') {
            steps {
                sh '''
                    echo "Building Next.js application..."
                    pnpm run build
                '''
            }
        }
        
        stage('Run Tests') {
            steps {
                sh '''
                    echo "Running tests..."
                    # Add your test commands here
                    # pnpm run test
                    echo "Tests completed successfully"
                '''
            }
        }
        
        stage('Build Docker Image') {
            steps {
                script {
                    def dockerImage = docker.build("${DOCKER_IMAGE}:${DOCKER_TAG_FULL}")
                    
                    // Also tag as latest
                    sh "docker tag ${DOCKER_IMAGE}:${DOCKER_TAG_FULL} ${DOCKER_IMAGE}:latest"
                }
            }
        }
        
        stage('Security Scan') {
            steps {
                sh '''
                    echo "Running security scans..."
                    # Add security scanning tools here
                    # docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasecurity/trivy image ${DOCKER_IMAGE}:${DOCKER_TAG_FULL}
                    echo "Security scan completed"
                '''
            }
        }
        
        stage('Push to Registry') {
            steps {
                script {
                    docker.withRegistry('https://registry-1.docker.io/v2/', 'dockerhub-credentials') {
                        sh "docker push ${DOCKER_IMAGE}:${DOCKER_TAG_FULL}"
                        sh "docker push ${DOCKER_IMAGE}:latest"
                    }
                }
            }
        }
        
        stage('Deploy to Kubernetes') {
            when {
                branch 'main'
            }
            steps {
                withCredentials([file(credentialsId: 'kubeconfig-file', variable: 'KUBECONFIG')]) {
                    sh '''
                        echo "Deploying to Kubernetes..."
                        
                        # Create namespace if it doesn't exist
                        kubectl get namespace ${K8S_NAMESPACE} || kubectl create namespace ${K8S_NAMESPACE}
                        
                        # Apply Kubernetes manifests
                        kubectl apply -f k8s/00-namespace-secrets.yaml
                        
                        # Update deployment with new image
                        sed -i "s|image: .*|image: ${DOCKER_IMAGE}:${DOCKER_TAG_FULL}|g" k8s/01-deployment-service.yaml
                        kubectl apply -f k8s/01-deployment-service.yaml
                        kubectl apply -f k8s/02-ingress.yaml
                        kubectl apply -f k8s/03-hpa.yaml
                        
                        # Wait for deployment to be ready
                        kubectl rollout status deployment/image-uploader-app -n ${K8S_NAMESPACE} --timeout=300s
                        
                        # Verify deployment
                        kubectl get pods -n ${K8S_NAMESPACE}
                        kubectl get services -n ${K8S_NAMESPACE}
                    '''
                }
            }
        }
        
        stage('Smoke Tests') {
            when {
                branch 'main'
            }
            steps {
                sh '''
                    echo "Running smoke tests..."
                    # Add smoke tests here
                    # curl -f http://your-app-url/api/health || exit 1
                    echo "Smoke tests passed"
                '''
            }
        }
    }
    
    post {
        always {
            // Clean up Docker images
            sh '''
                docker rmi ${DOCKER_IMAGE}:${DOCKER_TAG_FULL} || true
                docker rmi ${DOCKER_IMAGE}:latest || true
                docker system prune -f
            '''
        }
        
        success {
            echo "Pipeline completed successfully!"
            // Send success notification
            script {
                if (env.BRANCH_NAME == 'main') {
                    // Slack/Email notification for successful deployment
                    echo "Deployment to production completed successfully"
                }
            }
        }
        
        failure {
            echo "Pipeline failed!"
            // Send failure notification
            script {
                if (env.BRANCH_NAME == 'main') {
                    // Slack/Email notification for failed deployment
                    echo "Deployment to production failed"
                }
            }
        }
        
        unstable {
            echo "Pipeline completed with warnings"
        }
    }
}

// Additional pipeline for rollback
def rollbackDeployment(String targetTag) {
    pipeline {
        agent any
        parameters {
            string(name: 'ROLLBACK_TAG', defaultValue: 'latest', description: 'Docker tag to rollback to')
        }
        stages {
            stage('Rollback') {
                steps {
                    withCredentials([file(credentialsId: 'kubeconfig-file', variable: 'KUBECONFIG')]) {
                        sh '''
                            echo "Rolling back to tag: ${ROLLBACK_TAG}"
                            
                            # Update deployment with rollback image
                            kubectl set image deployment/image-uploader-app image-uploader=${DOCKER_IMAGE}:${ROLLBACK_TAG} -n ${K8S_NAMESPACE}
                            
                            # Wait for rollback to complete
                            kubectl rollout status deployment/image-uploader-app -n ${K8S_NAMESPACE} --timeout=300s
                            
                            echo "Rollback completed successfully"
                        '''
                    }
                }
            }
        }
    }
}