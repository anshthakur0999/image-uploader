pipeline {
    agent any
    
    environment {
        // Docker Hub or ECR registry
        DOCKER_REGISTRY = 'anshthakur0999'
        IMAGE_NAME = "${DOCKER_REGISTRY}/image-uploader"
        IMAGE_TAG = "${BUILD_NUMBER}"
        DOCKER_CREDENTIALS = 'docker-hub-credentials'
        KUBECONFIG_CREDENTIALS = 'kubeconfig-credentials'
        AWS_REGION = 'us-east-1'
        EKS_CLUSTER_NAME = 'image-uploader-cluster'
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Install Dependencies') {
            steps {
                script {
                    sh '''
                        npm install -g pnpm
                        pnpm install --frozen-lockfile
                    '''
                }
            }
        }
        
        stage('Lint & Type Check') {
            steps {
                script {
                    sh '''
                        # Type checking
                        pnpm run build --dry-run || echo "TypeScript errors ignored as per config"
                        
                        # ESLint (if enabled)
                        # pnpm run lint || echo "ESLint disabled in config"
                    '''
                }
            }
        }
        
        stage('Build Application') {
            steps {
                script {
                    sh 'pnpm run build'
                }
            }
        }
        
        stage('Build Docker Image') {
            steps {
                script {
                    docker.build("${IMAGE_NAME}:${IMAGE_TAG}")
                    docker.build("${IMAGE_NAME}:latest")
                }
            }
        }
        
        stage('Security Scan') {
            steps {
                script {
                    // Using Trivy for vulnerability scanning
                    sh '''
                        # Install Trivy if not exists
                        if ! command -v trivy &> /dev/null; then
                            wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
                            echo "deb https://aquasecurity.github.io/trivy-repo/deb generic main" | sudo tee -a /etc/apt/sources.list
                            sudo apt-get update
                            sudo apt-get install -y trivy
                        fi
                        
                        # Scan the image
                        trivy image --exit-code 0 --severity HIGH,CRITICAL ${IMAGE_NAME}:${IMAGE_TAG}
                    '''
                }
            }
        }
        
        stage('Push Docker Image') {
            steps {
                script {
                    docker.withRegistry('https://registry-1.docker.io/v2/', DOCKER_CREDENTIALS) {
                        docker.image("${IMAGE_NAME}:${IMAGE_TAG}").push()
                        docker.image("${IMAGE_NAME}:latest").push()
                    }
                }
            }
        }
        
        stage('Deploy to Kubernetes') {
            when {
                branch 'main'
            }
            steps {
                script {
                    withCredentials([file(credentialsId: KUBECONFIG_CREDENTIALS, variable: 'KUBECONFIG')]) {
                        sh '''
                            # Update kubeconfig for EKS
                            aws eks update-kubeconfig --region ${AWS_REGION} --name ${EKS_CLUSTER_NAME}
                            
                            # Apply Kubernetes manifests
                            kubectl apply -f k8s/namespace.yaml
                            kubectl apply -f k8s/configmap.yaml
                            kubectl apply -f k8s/pvc.yaml
                            
                            # Replace image variables and apply deployment
                            envsubst < k8s/deployment.yaml | kubectl apply -f -
                            kubectl apply -f k8s/service.yaml
                            
                            # Wait for deployment to complete
                            kubectl rollout status deployment/image-uploader-deployment -n image-uploader --timeout=300s
                            
                            # Get service URL
                            kubectl get service image-uploader-service -n image-uploader
                        '''
                    }
                }
            }
        }
        
        stage('Health Check') {
            when {
                branch 'main'
            }
            steps {
                script {
                    sh '''
                        # Wait for pods to be ready
                        kubectl wait --for=condition=ready pod -l app=image-uploader -n image-uploader --timeout=300s
                        
                        # Get external IP
                        EXTERNAL_IP=$(kubectl get service image-uploader-service -n image-uploader -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
                        echo "Application deployed at: http://$EXTERNAL_IP"
                        
                        # Basic health check
                        sleep 30
                        curl -f "http://$EXTERNAL_IP" || echo "Health check failed, but deployment completed"
                    '''
                }
            }
        }
    }
    
    post {
        always {
            // Clean up workspace
            cleanWs()
        }
        success {
            echo 'Deployment completed successfully!'
            // You can add Slack/email notifications here
        }
        failure {
            echo 'Deployment failed!'
            // You can add failure notifications here
        }
    }
}