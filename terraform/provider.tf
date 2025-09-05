# provider.tf

terraform {
  required_version = ">= 1.4.0"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.18"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
  }
}

# Kubernetes provider
provider "kubernetes" {
  config_path = var.kubeconfig
}

# Helm provider
provider "helm" {
  kubernetes {
    config_path = var.kubeconfig
  }
}