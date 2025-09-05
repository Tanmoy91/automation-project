# main.tf

# Kubernetes namespaces
resource "kubernetes_namespace" "apps" {
  metadata {
    name = var.apps_namespace
  }
}

resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = var.monitoring_namespace
  }
}

resource "kubernetes_namespace" "jenkins" {
  metadata {
    name = var.jenkins_namespace
  }
}

# Helm release: Nginx
resource "helm_release" "nginx" {
  name       = "my-nginx"
  namespace  = kubernetes_namespace.apps.metadata[0].name
  chart      = "../helm-charts/my-nginx"

  values = [
    file("../helm-charts/my-nginx/values.yaml")
  ]
}

# Helm release: Monitoring stack
resource "helm_release" "monitoring" {
  name       = "monitoring-stack"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  chart      = "../helm-charts/monitoring-stack"

  values = [
    file("../helm-charts/monitoring-stack/values.yaml")
  ]
}

# Helm release: Jenkins
resource "helm_release" "jenkins" {
  name       = "jenkins"
  namespace  = kubernetes_namespace.jenkins.metadata[0].name
  chart      = "../helm-charts/jenkins"

  values = [
    file("../helm-charts/jenkins/values.yaml")
  ]
}