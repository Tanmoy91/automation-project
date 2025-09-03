pipeline {
  agent any   // runs on Jenkins itself
  environment {
    IMAGE = "tanmoyjames/my-nginx"
    TAG = "${env.BUILD_NUMBER}"
    CHART_PATH = "helm-charts/my-nginx"
    RELEASE = "my-nginx"
    NAMESPACE = "apps"
  }
  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Build & Push with Kaniko') {
      steps {
        sh '''
        # Delete old pod if exists
        kubectl delete pod kaniko-${BUILD_NUMBER} -n jenkins --ignore-not-found=true

        # Run kaniko pod
        cat <<EOF | kubectl apply -f -
        apiVersion: v1
        kind: Pod
        metadata:
          name: kaniko-${BUILD_NUMBER}
          namespace: jenkins
        spec:
          restartPolicy: Never
          serviceAccountName: jenkins
          containers:
          - name: kaniko
            image: gcr.io/kaniko-project/executor:latest
            args:
              - "--context=git://github.com/Tanmoy91/automation-project.git#${GIT_COMMIT}"
              - "--dockerfile=helm-charts/my-nginx/Dockerfile"
              - "--destination=${IMAGE}:${TAG}"
              - "--destination=${IMAGE}:latest"
            volumeMounts:
              - name: docker-config
                mountPath: /kaniko/.docker/
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

        # Wait for build to finish
        kubectl wait --for=condition=Succeeded pod/kaniko-${BUILD_NUMBER} -n jenkins --timeout=10m
        '''
      }
    }

    stage('Deploy with Helm') {
      steps {
        sh '''
        helm upgrade --install ${RELEASE} ${CHART_PATH} -n ${NAMESPACE} \
          --set image.repository=${IMAGE} \
          --set image.tag=${TAG} \
          --wait --timeout 3m
        '''
      }
    }
  }
}
