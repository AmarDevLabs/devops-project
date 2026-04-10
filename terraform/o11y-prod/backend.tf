terraform {
  backend "s3" {
    bucket         = "amar-devops-tfstate-2026-001"
    key            = "observability-prod/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "terraform-locks"
  }
}
