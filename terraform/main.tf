terraform {
  required_version = ">= 1.0.0"

  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

provider "local" {}

resource "local_file" "devops_file" {
content = "DevOps Terraform Setup - Step 1"
filename = "devops.txt"
}
