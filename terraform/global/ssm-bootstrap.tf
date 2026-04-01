locals {
  bootstrap_script      = file("${path.module}/../scripts/bootstrap.sh")
  bootstrap_script_hash = substr(sha256(local.bootstrap_script), 0, 8)
}

resource "aws_ssm_document" "bootstrap" {
  name          = "bootstrap-kubernetes-${local.bootstrap_script_hash}"
  document_type = "Command"

  content = jsonencode({
    schemaVersion = "2.2"
    description   = "Bootstrap Kubernetes nodes"

    mainSteps = [
      {
        action = "aws:runShellScript"
        name   = "bootstrap"

        inputs = {
          runCommand = concat(
            [
              "cat > /tmp/bootstrap.sh <<'__BOOTSTRAP_SCRIPT_EOF__'"
            ],
            split("\n", local.bootstrap_script),
            [
              "__BOOTSTRAP_SCRIPT_EOF__",
              "chmod +x /tmp/bootstrap.sh",
              "sudo bash /tmp/bootstrap.sh > /var/log/bootstrap-k8s.log 2>&1"
            ]
          )
        }
      }
    ]
  })
}

resource "aws_ssm_association" "dev_bootstrap" {
  name = aws_ssm_document.bootstrap.name

  targets {
    key    = "InstanceIds"
    values = [var.dev_instance_id]
  }
}

resource "aws_ssm_association" "prod_bootstrap" {
  name = aws_ssm_document.bootstrap.name

  targets {
    key    = "InstanceIds"
    values = [var.prod_instance_id]
  }
}
