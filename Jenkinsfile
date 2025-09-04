pipeline {
  agent any

  environment {
    APP_NS        = 'apps'                          // nginx runs here
    DOCKER_REPO   = 'tanmoyjames/my-nginx'          // your DockerHub repo
    IMAGE_TAG     = "${env.BUILD_NUMBER}"           // build number as tag
    KANIKO_IMAGE  = 'gcr.io/kaniko-project/executor:latest'
    KUBECTL_URL   = 'https://dl.k8s.io/release/v1.30.3/bin/linux/amd64/kubectl'
    DOCKERCFG_MNT = '/kaniko/.docker'               // where dockerhub-secret mounts
  }

  options {
    timestamps()
  }

  stages {
    stage('Prep') {
      steps {
        sh '''
          set -e
          # Ensure kubectl is available in Jenkins container
          if ! command -v kubectl >/dev/null 2>&1; then
            echo "Downloading kubectl..."
            curl -fsSL -o kubectl ${KUBECTL_URL}
            chmod +x kubectl
            sudo mv kubectl /usr/local/bin/ || mv kubectl ${WORKSPACE}/kubectl && export PATH=${WORKSPACE}:$PATH
          fi

          # Fallback CONTEXT if GIT_URL not exported
          if [ -z "${GIT_URL}" ]; then
            GURL=$(git config --get remote.origin.url || true)
            if [ -n "$GURL" ]; then
              echo "GIT_URL from git remote: $GURL"
              echo "GIT_URL=$GURL" >> ${WORKSPACE}/.env
            fi
          fi
        '''
      }
    }

    stage('Build & Push Image (Kaniko Job)') {
      steps {
        sh '''
          set -e

          # Clean any previous job
          kubectl -n ${APP_NS} delete job kaniko-build --ignore-not-found=true

          # Resolve context
          GIT_REMOTE=$(git config --get remote.origin.url)
          BRANCH_NAME=${BRANCH_NAME:-main}
          GIT_SHA=$(git rev-parse --short=12 HEAD)
          [ -z "$GIT_REMOTE" ] && { echo "No git remote found"; exit 1; }

          cat <<EOF > /tmp/kaniko-job.yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: kaniko-build
  namespace: ${APP_NS}
spec:
  backoffLimit: 0
  template:
    spec:
      serviceAccountName: jenkins-sa
      restartPolicy: Never
      containers:
      - name: kaniko
        image: ${KANIKO_IMAGE}
        args:
          - --context=${GIT_REMOTE}#refs/heads/${BRANCH_NAME}
          - --dockerfile=helm-charts/my-nginx/Dockerfile
          - --destination=${DOCKER_REPO}:${IMAGE_TAG}
          - --destination=${DOCKER_REPO}:latest
          - --snapshotMode=time
          - --verbosity=debug
          - --docker-config=${DOCKERCFG_MNT}
        volumeMounts:
        - name: docker-config
          mountPath: ${DOCKERCFG_MNT}
      volumes:
      - name: docker-config
        projected:
          sources:
          - secret:
              name: dockerhub-secret
              items:
              - key: .dockerconfigjson
                path: config.json
EOF

          echo "Applying Kaniko Job..."
          kubectl apply -f /tmp/kaniko-job.yaml

          echo "Waiting for Kaniko to complete..."
          kubectl -n ${APP_NS} wait --for=condition=complete job/kaniko-build --timeout=15m || {
            echo "❌ Kaniko job failed or timed out. Dumping pod logs..."
            kubectl -n ${APP_NS} logs -l job-name=kaniko-build --all-containers=true --tail=200 || true
            exit 1
          }

          echo "✅ Kaniko job completed successfully."
          echo "Kaniko logs:"
          kubectl -n ${APP_NS} logs -l job-name=kaniko-build --all-containers=true --tail=100 || true
        '''
      }
    }

    stage('Deploy (rollout new image)') {
      steps {
        sh '''
          set -e
          # Update Deployment image (container name = nginx in chart)
          kubectl -n ${APP_NS} set image deployment/my-nginx nginx=${DOCKER_REPO}:${IMAGE_TAG}

          # Wait for rollout to finish
          kubectl -n ${APP_NS} rollout status deployment/my-nginx --timeout=5m
        '''
      }
    }
  }

  post {
    always {
      sh '''
        # Cleanup Kaniko job (optional)
        kubectl -n ${APP_NS} delete job kaniko-build --ignore-not-found=true || true
      '''
    }
  }
}
