variable "aws_region" {
  description = "AWS region name"
  type        = string
}

variable "prod_ami" {
  description = "AMI for prod EC2"
  type        = string
}

variable "prod_instance_type" {
  description = "Instance type"
  type        = string
  default     = "t3.micro"
}
