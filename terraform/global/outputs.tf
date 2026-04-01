output "ssm_instance_profile_name" {
  value = aws_iam_instance_profile.ec2_ssm_profile.name
}

output "ssm_role_name" {
  value = aws_iam_role.ec2_ssm_role.name
}
