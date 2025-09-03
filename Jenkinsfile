pipeline {
  agent {
    kubernetes {
      // ephemeral pod definition Jenkins will create for each build
      yaml """
apiVersion: v1
kind: Pod
metadata:
  labels:
    jenkins/label: kaniko-helm
spec:
  serviceAccountName: jenkins
  restartPolicy: Never
  containers:
  - name: kaniko
    image: gcr.io/kaniko-project/executor:latest
    command:
      - cat
    tty: true
    volumeMounts:
      - name: docker-config
        mountPath: /kaniko/.docker/
  - name: helm
    image: lachlanevenson/k8s-helm:3.12.4
    command:
      - cat
    tty: true
  volumes:
  - name: docker-config
    projected:
      sources:
      - secret:
          name: dockerhub-secret
          items:
            - key: .dockerconfigjson
              path: config.json
"""
    }
  }

  environment {
    IMAGE = "tanmoyjames/my-nginx"   // <-- change this to your Docker Hub user
    CHART_PATH = "helm-charts/my-nginx"
    RELEASE = "my-nginx"
    NAMESPACE = "apps"
    TAG = "${env.BUILD_NUMBER}"
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Build & Push (Kaniko)') {
      steps {
        container('kaniko') {
          sh '''
            echo "Building image ${IMAGE}:${TAG} with Kaniko..."
            /kaniko/executor \
              --context ${WORKSPACE}/${CHART_PATH} \
              --dockerfile ${WORKSPACE}/${CHART_PATH}/Dockerfile \
              --destination ${IMAGE}:${TAG} \
              --destination ${IMAGE}:latest
          '''
        }
      }
    }

    stage('Deploy (Helm)') {
      steps {
        container('helm') {
          sh '''
            echo "Deploying with Helm -> ${RELEASE} using image ${IMAGE}:${TAG}"
            helm upgrade --install ${RELEASE} ${CHART_PATH} -n ${NAMESPACE} \
              --set image.repository=${IMAGE} \
              --set image.tag=${TAG} \
              --wait --timeout 3m
          '''
        }
      }
    }
  }

  post {
    success { echo "Build + Deploy complete: ${IMAGE}:${TAG}" }
    failure { echo "Pipeline failed — check logs" }
  }
}
