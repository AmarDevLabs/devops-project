locals {
  k8s_init_script = file("${path.module}/../scripts/k8s-init.sh")
}

resource "aws_ssm_document" "prod_k8s_init" {
  name            = "prod-k8s-init"
  document_type   = "Command"
  document_format = "JSON"

  content = jsonencode({
    schemaVersion = "2.2"
    description   = "Initialize Kubernetes cluster on prod EC2 instance"

    mainSteps = [
      {
        action = "aws:runShellScript"
        name   = "runK8sInit"
        inputs = {
          runCommand = split("\n", local.k8s_init_script)
        }
      }
    ]
  })
}

resource "aws_ssm_association" "prod_k8s_init" {
  name = aws_ssm_document.prod_k8s_init.name

  targets {
    key    = "InstanceIds"
    values = [aws_instance.prod_ec2.id]
  }

  depends_on = [
    aws_instance.prod_ec2
  ]
}
