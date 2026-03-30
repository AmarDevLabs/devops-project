terraform {
  backend "s3" {
    bucket         = "amar-devops-dev-1"
    key            = "devops-project/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
