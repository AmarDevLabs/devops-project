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
  content  = var.file_content
  filename = var.file_name
}

provider "aws" {
  region = var.aws_region
}


# DEV bucket
resource "aws_s3_bucket" "dev_bucket" {
  bucket = "amar-devops-dev-2026-001"

  lifecycle {
    prevent_destroy = true
  }
}

# PROD bucket
resource "aws_s3_bucket" "prod_bucket" {
  bucket = "amar-prod-devops-2026-001-ap-south-1"

  lifecycle {
    prevent_destroy = true
  }
}
# Generate SSH key for dev environment
resource "tls_private_key" "dev_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "dev_key_pair" {
  key_name   = "dev-ec2-key"
  public_key = tls_private_key.dev_key.public_key_openssh
}

# Generate SSH key for prod environment
resource "tls_private_key" "prod_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "prod_key_pair" {
  key_name   = "prod-ec2-key"
  public_key = tls_private_key.prod_key.public_key_openssh
}

# Default VPC
data "aws_vpc" "default" {
  default = true
}

# Security group for dev
resource "aws_security_group" "dev_sg" {
  name        = "dev-ec2-sg"
  description = "Allow SSH"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security group for prod
resource "aws_security_group" "prod_sg" {
  name        = "prod-ec2-sg"
  description = "Allow SSH"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "dev_ec2" {
  ami                    = "ami-0931307dcdc2a28c9" # Verified AMI
  instance_type          = "t3.micro"              # Free Tier eligible
  key_name               = aws_key_pair.dev_key_pair.key_name
  vpc_security_group_ids = [aws_security_group.dev_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_ssm_profile.name
  user_data              = file("${path.module}/scripts/bootstrap.sh")

  tags = {
    Name = "dev-ec2-instance"
    Env  = "dev"
  }
  lifecycle {
    prevent_destroy = true
    ignore_changes  = [user_data]
  }
}

resource "aws_instance" "prod_ec2" {
  ami                    = "ami-0931307dcdc2a28c9" # Verified AMI
  instance_type          = "t3.micro"              # Free Tier eligible
  key_name               = aws_key_pair.prod_key_pair.key_name
  vpc_security_group_ids = [aws_security_group.prod_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_ssm_profile.name
  user_data              = file("${path.module}/scripts/bootstrap.sh")

  tags = {
    Name = "prod-ec2-instance"
    Env  = "prod"
  }
  lifecycle {
    prevent_destroy = true
    ignore_changes  = [user_data]
  }
}

# Outputs
output "dev_private_key" {
  value     = tls_private_key.dev_key.private_key_pem
  sensitive = true
}

output "dev_public_ip" {
  value = aws_instance.dev_ec2.public_ip
}

output "prod_private_key" {
  value     = tls_private_key.prod_key.private_key_pem
  sensitive = true
}

output "prod_public_ip" {
  value = aws_instance.prod_ec2.public_ip
}
