variable "aws_region" {
  type = string
}
variable "dev_instance_id" {
  description = "EC2 instance ID for dev"
  type        = string
}

variable "prod_instance_id" {
  description = "EC2 instance ID for prod"
  type        = string
}
