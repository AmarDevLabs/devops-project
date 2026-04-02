Project Overview

Production-style DevOps infrastructure built using:

Terraform (Infrastructure as Code)
AWS (EC2, S3, IAM, SSM)
GitHub Actions (CI/CD)
Kubernetes (kubeadm)
containerd runtime

All infrastructure and execution are managed through Terraform and AWS Systems Manager (SSM). No SSH access is used.

Architecture Summary

Environments:

global — shared infrastructure (IAM, SSM, backend)
dev — development environment
prod — production environment

Each environment uses separate:

Terraform state
EC2 instances
Kubernetes clusters

Remote state is stored in:

S3 bucket
DynamoDB lock table
CI/CD Workflow Summary

Pull Request:

Terraform plan runs for:
global
dev
prod

Merge to main:

global apply runs automatically
dev apply runs automatically
prod workflow starts automatically

Production:

Requires manual approval before apply
Protected using GitHub Environment rules
Access Model

Instances are accessed using:

AWS Systems Manager (SSM)

SSH access is disabled.

Kubernetes Setup

Kubernetes components are installed using Terraform-managed SSM execution.

Bootstrap installs:

containerd
kubeadm
kubelet
kubectl
required kernel settings

Each environment runs:

Independent Kubernetes cluster
Single-node control-plane setup
Deployment Flow

PR Created
→ Terraform plan runs

PR Merged
→ global apply
→ dev apply
→ prod workflow starts

Approval Given
→ prod apply runs

Future Enhancements

Planned improvements:

Multi-node Kubernetes clusters
Helm-based deployments
Monitoring and logging stack
Ingress and TLS configuration
