variable "aws_region" {
  description = "AWS region name"
  type        = string
}

variable "dev_ami" {
  description = "AMI for dev EC2 instance"
  type        = string
}

variable "dev_instance_type" {
  description = "Instance type for dev EC2 instance"
  type        = string
  default     = "t3.micro"
}
