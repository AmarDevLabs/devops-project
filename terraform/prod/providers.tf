provider "aws" {
  region = var.aws_region
}

data "aws_vpc" "default" {
  default = true
}

data "terraform_remote_state" "global" {
  backend = "s3"

  config = {
    bucket = "amar-devops-tfstate-2026-001"
    key    = "global/devops-project/terraform.tfstate"
    region = var.aws_region
  }
}
