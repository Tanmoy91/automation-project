pipeline {
  agent any

  environment {
    APP_NS        = 'apps'                          // nginx runs here
    DOCKER_REPO   = '<your-dockerhub-user>/my-nginx'// change this!
    IMAGE_TAG     = "${env.BUILD_NUMBER}"           // or use GIT_COMMIT
    KANIKO_IMAGE  = 'gcr.io/kaniko-project/executor:latest'
    KUBECTL_URL   = 'https://dl.k8s.io/release/v1.30.3/bin/linux/amd64/kubectl'
    CONTEXT_PATH  = "git://${env.GIT_URL?.replace('https://','') ?: ''}" // fallback set below
    DOCKERCFG_MNT = '/kaniko/.docker'               // where dockerhub-secret will mount
  }

  options {
    timestamps()
    ansiColor('xterm')
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

          # Fallback CONTEXT if GIT_URL not exported (some SCM configs)
          if [ -z "${GIT_URL}" ]; then
            # Use the current repo remote
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

          # Resolve context: build directly from git@commit for reproducibility
          GIT_REMOTE=$(git config --get remote.origin.url)
          GIT_SHA=$(git rev-parse --short=12 HEAD)
          [ -z "$GIT_REMOTE" ] && { echo "No git remote found"; exit 1; }

          cat <<'EOF' > /tmp/kaniko-job.yaml
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
          - --context=${GIT_REMOTE}
          - --git=branch=${BRANCH_NAME:-main}
          - --dockerfile=helm-charts/my-nginx/Dockerfile
          - --destination=${DOCKER_REPO}:${IMAGE_TAG}
          - --destination=${DOCKER_REPO}:latest
          - --snapshotMode=time
          - --use-new-run
          - --verbosity=info
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
          kubectl -n ${APP_NS} wait --for=condition=complete job/kaniko-build --timeout=15m
          echo "Kaniko logs:"
          kubectl -n ${APP_NS} logs job/kaniko-build --all-containers=true || true
        '''
      }
    }

    stage('Deploy (rollout new image)') {
      steps {
        sh '''
          set -e
          # Update the Deployment image (container name is 'nginx' in your chart)
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
