pipeline {
  agent any

  environment {
    APP_NS        = 'apps'
    DOCKER_REPO   = 'tanmoyjames/my-nginx'
    IMAGE_TAG     = "${env.BUILD_NUMBER}"
    KANIKO_JOB    = "${WORKSPACE}/kaniko-job.yaml"
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
          kubectl -n ${APP_NS} delete job kaniko-build --ignore-not-found=true

          echo "Creating job with image ${DOCKER_REPO}:${IMAGE_TAG} ..."
          cp ${KANIKO_JOB} kaniko-job-build.yaml
          sed -i "s|__IMAGE__|${DOCKER_REPO}:${IMAGE_TAG}|g" kaniko-job-build.yaml

          kubectl apply -f kaniko-job-build.yaml -n ${APP_NS}

          kubectl -n ${APP_NS} wait --for=condition=complete job/kaniko-build --timeout=15m || {
            echo "❌ Kaniko job failed or timed out"
            kubectl -n ${APP_NS} logs -l job-name=kaniko-build --all-containers=true --tail=200 || true
            exit 1
          }

          echo "✅ Kaniko job pushed image ${DOCKER_REPO}:${IMAGE_TAG}"
        '''
      }
    }

    stage('Deploy (rollout new image)') {
      steps {
        sh '''
          set -e
          kubectl -n ${APP_NS} set image deployment/my-nginx-my-nginx nginx=${DOCKER_REPO}:${IMAGE_TAG}
          kubectl -n ${APP_NS} rollout status deployment/my-nginx-my-nginx --timeout=5m
        '''
      }
    }
  }

  post {
    always {
      sh '''
        kubectl -n ${APP_NS} delete job kaniko-build --ignore-not-found=true || true
      '''
    }
  }
}
