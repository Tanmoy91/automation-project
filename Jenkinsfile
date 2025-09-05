pipeline {
  agent any

  environment {
    APP_NS        = 'apps'                          // namespace
    DOCKER_REPO   = 'tanmoyjames/my-nginx'          // DockerHub repo
    IMAGE_TAG     = "${env.BUILD_NUMBER}"           // Jenkins build number
    KANIKO_JOB    = "${WORKSPACE}/kaniko-job.yaml"  // YAML file (template-based)
    KUBECTL_URL   = 'https://dl.k8s.io/release/v1.30.3/bin/linux/amd64/kubectl'
  }

  options {
    timestamps()
  }

  stages {
    stage('Prep') {
      steps {
        sh '''
          set -e
          # Ensure kubectl is installed
          if ! command -v kubectl >/dev/null 2>&1; then
            echo "Downloading kubectl..."
            curl -fsSL -o kubectl ${KUBECTL_URL}
            chmod +x kubectl
            sudo mv kubectl /usr/local/bin/ || mv kubectl ${WORKSPACE}/kubectl && export PATH=${WORKSPACE}:$PATH
          fi
        '''
      }
    }

    stage('Build & Push Image (Kaniko Job)') {
      steps {
        sh '''
          set -e
          # Clean up any old job
          kubectl -n ${APP_NS} delete job kaniko-build --ignore-not-found=true

          echo "Substituting image repo/tag in Kaniko job..."
          sed -i "s|__IMAGE__|${DOCKER_REPO}:${IMAGE_TAG}|g" ${KANIKO_JOB}

          echo "Applying Kaniko Job YAML..."
          kubectl apply -f ${KANIKO_JOB} -n ${APP_NS}

          echo "Waiting for Kaniko job to complete..."
          kubectl -n ${APP_NS} wait --for=condition=complete job/kaniko-build --timeout=15m || {
            echo "❌ Kaniko job failed or timed out. Dumping logs..."
            kubectl -n ${APP_NS} logs -l job-name=kaniko-build --all-containers=true --tail=200 || true
            exit 1
          }

          echo "✅ Kaniko job completed successfully."
          kubectl -n ${APP_NS} logs -l job-name=kaniko-build --all-containers=true --tail=100 || true
        '''
      }
    }

    stage('Deploy (rollout new image)') {
      steps {
        sh '''
          set -e
          kubectl -n ${APP_NS} set image deployment/my-nginx nginx=${DOCKER_REPO}:${IMAGE_TAG}
          kubectl -n ${APP_NS} rollout status deployment/my-nginx --timeout=5m
        '''
      }
    }
  }

  post {
    always {
      sh '''
        echo "Cleaning up Kaniko job..."
        kubectl -n ${APP_NS} delete job kaniko-build --ignore-not-found=true || true
      '''
    }
  }
}
