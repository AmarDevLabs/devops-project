output "dev_private_key" {
  value     = tls_private_key.dev_key.private_key_pem
  sensitive = true
}

output "dev_public_ip" {
  value = aws_instance.dev_ec2.public_ip
}
