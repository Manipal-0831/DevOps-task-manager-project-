pipeline {
  agent any
  environment {
    REGISTRY = "ghcr.io/<YOUR_GH_USER>"       // change to your registry
    BACKEND_IMAGE = "${REGISTRY}/taskmgr-backend"
    FRONTEND_IMAGE = "${REGISTRY}/taskmgr-frontend"
    K8S_DIR = "k8s"
    GIT_USER = "jenkins-bot"
    GIT_EMAIL = "jenkins-bot@example.com"
  }
  stages {
    stage('Checkout') { steps { checkout scm } }

    stage('Unit tests & Lint') {
      parallel {
        stage('Backend tests') {
          steps {
            dir('backend') {
              sh 'pip install -r requirements.txt'
              sh 'pytest -q || true'    // change to exit non-zero if you want fail
            }
          }
        }
        stage('Frontend tests') {
          steps {
            dir('frontend') {
              sh 'npm ci'
              sh 'npm test --silent || true'
            }
          }
        }
      }
    }

    stage('Build images') {
      steps {
        sh "docker build -t ${BACKEND_IMAGE}:${GIT_COMMIT} ./backend"
        sh "docker build -t ${FRONTEND_IMAGE}:${GIT_COMMIT} ./frontend"
      }
    }

    stage('Registry login & Push') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'reg-creds', usernameVariable: 'REG_USER', passwordVariable: 'REG_PASS')]) {
          sh 'echo $REG_PASS | docker login ghcr.io -u $REG_USER --password-stdin'
          sh "docker push ${BACKEND_IMAGE}:${GIT_COMMIT}"
          sh "docker push ${FRONTEND_IMAGE}:${GIT_COMMIT}"
        }
      }
    }

    stage('Security scans & SBOM') {
      steps {
        sh '''
          # Trivy (images)
          if command -v trivy >/dev/null 2>&1; then
            trivy image --severity HIGH,CRITICAL --no-progress ${BACKEND_IMAGE}:${GIT_COMMIT} || true
            trivy image --severity HIGH,CRITICAL --no-progress ${FRONTEND_IMAGE}:${GIT_COMMIT} || true
          else
            echo "trivy not present on node — skip"
          fi

          # Bandit for backend code
          pip install bandit || true
          bandit -r backend || true

          # SBOM using syft (optional)
          if command -v syft >/dev/null 2>&1; then
            syft ${BACKEND_IMAGE}:${GIT_COMMIT} -o json > sbom-backend-${GIT_COMMIT}.json || true
          fi
        '''
      }
    }

    stage('Update k8s manifest in Git') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'git-creds', usernameVariable: 'GITUSR', passwordVariable: 'GITPAT')]) {
          sh '''
            # update backend image
            sed -i "s|image: .*taskmgr-backend.*|image: ${BACKEND_IMAGE}:${GIT_COMMIT}|" ${K8S_DIR}/backend-deployment.yaml

            git config user.email "${GIT_EMAIL}"
            git config user.name "${GIT_USER}"
            git remote set-url origin https://${GITUSR}:${GITPAT}@$(git config --get remote.origin.url | sed 's#https://##')
            git add ${K8S_DIR}/backend-deployment.yaml
            git commit -m "ci: update backend image ${GIT_COMMIT}" || true
            git push origin HEAD
          '''
        }
      }
    }

    stage('Done') { steps { echo 'Jenkins pipeline finished' } }
  }
}
