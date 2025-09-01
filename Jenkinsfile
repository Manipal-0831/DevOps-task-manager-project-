pipeline {
  agent any

  environment {
    REGISTRY = "mani0831"
    FRONT = "myapp-frontend"
    BACK  = "myapp-backend"
  }

  stages {

    stage('Checkout') {
      steps {
        checkout scm
        script { IMAGE_TAG = "1.0.${env.BUILD_NUMBER}" }
        echo "IMAGE_TAG=${IMAGE_TAG}"
      }
    }

    stage('Terraform Apply') {
      steps {
        echo "Running Terraform to provision infra..."
        sh '''
          cd infra/terraform
          terraform init
          terraform apply -auto-approve
        '''
      }
    }

    stage('Build Docker Images') {
      steps {
        sh "docker build -t ${REGISTRY}/${FRONT}:${IMAGE_TAG} ./frontend"
        sh "docker build -t ${REGISTRY}/${BACK}:${IMAGE_TAG} ./backend"
      }
    }

    stage('Push Images to DockerHub') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
          sh '''
            echo $DOCKER_PASS | docker login -u "$DOCKER_USER" --password-stdin
            docker push ${REGISTRY}/${FRONT}:${IMAGE_TAG}
            docker push ${REGISTRY}/${BACK}:${IMAGE_TAG}
            docker logout
          '''
        }
      }
    }

    stage('Update k8s Manifests & Push to GitHub') {
      steps {
        withCredentials([string(credentialsId: 'github-pat', variable: 'GITHUB_PAT')]) {
          sh '''
            # Update frontend & backend deployment manifests with new image tag
            sed -i 's|image: .*'${FRONT}':.*|image: '${REGISTRY}'/'${FRONT}':'${IMAGE_TAG}'|' k8s/frontend-deployment.yaml || true
            sed -i 's|image: .*'${BACK}':.*|image: '${REGISTRY}'/'${BACK}':'${IMAGE_TAG}'|' k8s/backend-deployment.yaml || true

            git config user.email "ci-bot@manipal"
            git config user.name "ci-bot"
            git add k8s/frontend-deployment.yaml k8s/backend-deployment.yaml || true
            git commit -m "ci: update images ${IMAGE_TAG}" || echo "no changes to commit"
            git push https://${GITHUB_PAT}@github.com/Manipal-0831/DevOps-task-manager-project.git HEAD:main || echo "push failed"
          '''
        }
      }
    }

    stage('Deploy Kubernetes Resources') {
      steps {
        sh '''
          # Apply all k8s manifests
          kubectl apply -f k8s/backend-deployment.yaml
          kubectl apply -f k8s/backend-service.yaml
          kubectl apply -f k8s/backend-hpa.yaml
          kubectl apply -f k8s/frontend-deployment.yaml
          kubectl apply -f k8s/frontend-service.yaml
          kubectl apply -f k8s/fastapi-servicemonitor.yaml
          kubectl apply -f k8s/load-generator.yaml
          kubectl apply -f k8s/netpol-backend.yaml
          kubectl apply -f k8s/secret-app.yaml
        '''
      }
    }

    stage('Deploy ArgoCD Manifests') {
      steps {
        sh '''
          # Apply ArgoCD manifests (only needed the first time)
          kubectl apply -f argocd/
        '''
      }
    }

    stage('Finish') {
      steps {
        echo "Pipeline complete: Terraform applied, images built & pushed, k8s resources deployed, monitoring & HPA ready, ArgoCD sync ready."
      }
    }

  }
}
