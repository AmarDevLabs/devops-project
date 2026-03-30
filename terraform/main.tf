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

data "aws_ami" "amazon_linux_free" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_s3_bucket" "example" {
  bucket = var.bucket_name
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

  tags = {
    Name = "dev-ec2-instance"
    Env  = "dev"
  }
}

resource "aws_instance" "prod_ec2" {
  ami                    = "ami-0931307dcdc2a28c9" # Verified AMI
  instance_type          = "t3.micro"              # Free Tier eligible
  key_name               = aws_key_pair.prod_key_pair.key_name
  vpc_security_group_ids = [aws_security_group.prod_sg.id]

  tags = {
    Name = "prod-ec2-instance"
    Env  = "prod"
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
