resource "aws_s3_bucket" "dev_bucket" {
  bucket = "amar-devops-dev-2026-001"

  lifecycle {
    prevent_destroy = true
  }
}

resource "tls_private_key" "dev_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "dev_key_pair" {
  key_name   = "dev-ec2-key"
  public_key = tls_private_key.dev_key.public_key_openssh
}

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

resource "aws_instance" "dev_ec2" {
  ami                    = var.dev_ami
  instance_type          = var.dev_instance_type
  key_name               = aws_key_pair.dev_key_pair.key_name
  vpc_security_group_ids = [aws_security_group.dev_sg.id]
  iam_instance_profile   = data.terraform_remote_state.global.outputs.ssm_instance_profile_name
  user_data              = file("${path.module}/../scripts/bootstrap.sh")

  tags = {
    Name = "dev-ec2-instance"
    Env  = "dev"
  }

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [user_data]
  }
}
