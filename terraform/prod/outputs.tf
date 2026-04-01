output "prod_private_key" {
  value     = tls_private_key.prod_key.private_key_pem
  sensitive = true
}

output "prod_public_ip" {
  value = aws_instance.prod_ec2.public_ip
}
