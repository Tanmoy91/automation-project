pipeline {
    agent any

    environment {
        DOCKER_IMAGE = "tanmoyjames/my-nginx"
        DOCKER_CREDS = credentials('dockerhub-creds')
    }

    stages {
        stage('Build & Push Image with Kaniko') {
            steps {
                script {
                    sh """
                    kubectl delete pod kaniko-${BUILD_NUMBER} -n jenkins --ignore-not-found=true

                    cat <<EOF | kubectl apply -f -
                    apiVersion: v1
                    kind: Pod
                    metadata:
                      name: kaniko-${BUILD_NUMBER}
                      namespace: jenkins
                    spec:
                      serviceAccountName: kaniko-sa
                      restartPolicy: Never
                      containers:
                      - name: kaniko
                        image: gcr.io/kaniko-project/executor:latest
                        args: [
                          "--dockerfile=helm-charts/my-nginx/Dockerfile",
                          "--context=git://github.com/tanmoy91/automation-project.git#refs/heads/main",
                          "--destination=${DOCKER_IMAGE}:${BUILD_NUMBER}",
                          "--destination=${DOCKER_IMAGE}:latest"
                        ]
                        volumeMounts:
                        - name: docker-config
                          mountPath: /kaniko/.docker/
                      volumes:
                      - name: docker-config
                        secret:
                          secretName: dockerhub-secret
                    EOF

                    kubectl wait --for=condition=Ready pod/kaniko-${BUILD_NUMBER} -n jenkins --timeout=300s
                    kubectl logs -f kaniko-${BUILD_NUMBER} -n jenkins
                    """
                }
            }
        }

        stage('Deploy with Helm') {
            steps {
                sh """
                helm upgrade --install my-nginx ./helm-charts/my-nginx -n apps \
                  --set image.repository=${DOCKER_IMAGE} \
                  --set image.tag=${BUILD_NUMBER}
                """
            }
        }
    }
}
