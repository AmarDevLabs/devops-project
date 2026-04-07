resource "aws_s3_bucket" "prod_bucket" {
  bucket = "amar-prod-devops-2026-001-ap-south-1"

  lifecycle {
    prevent_destroy = true
  }
}

resource "tls_private_key" "prod_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "prod_key_pair" {
  key_name   = "prod-ec2-key"
  public_key = tls_private_key.prod_key.public_key_openssh
}

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

resource "aws_instance" "prod_ec2" {
  ami                    = var.prod_ami
  instance_type          = var.prod_instance_type
  key_name               = aws_key_pair.prod_key_pair.key_name
  vpc_security_group_ids = [aws_security_group.prod_sg.id]

  iam_instance_profile = data.terraform_remote_state.global.outputs.ssm_instance_profile_name

  user_data = file("${path.module}/../scripts/bootstrap.sh")
  
  root_block_device {
    volume_size           = 15
    volume_type           = "gp3"
    delete_on_termination = true
  }
  

  tags = {
    Name = "prod-ec2-instance"
    Env  = "prod"
  }

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [user_data]
  }
}
