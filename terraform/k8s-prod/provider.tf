terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.30"
    }
  }

  backend "s3" {
    bucket         = "amar-prod-devops-2026-001-ap-south-1"
    key            = "k8s-prod/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "terraform-locks"
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}
