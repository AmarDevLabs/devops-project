resource "aws_iam_role" "ec2_ssm_role" {
  name = "devops-project-ec2-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Project   = "devops-project"
    ManagedBy = "Terraform"
  }
}

resource "aws_iam_role_policy_attachment" "ec2_ssm_core" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_ssm_profile" {
  name = "devops-project-ec2-ssm-profile"
  role = aws_iam_role.ec2_ssm_role.name

  tags = {
    Project   = "devops-project"
    ManagedBy = "Terraform"
  }
}
