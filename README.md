Writing
🚀 DevOps Infrastructure Project

This project builds a production-style DevOps platform using Terraform, AWS, GitHub Actions, Kubernetes, and SSM — with full infrastructure-as-code and no SSH access.

🏗️ Architecture Overview
Technologies Used
Terraform — Infrastructure as Code
AWS EC2 — Compute
AWS S3 — Remote Terraform State
AWS DynamoDB — State Locking
AWS IAM — Roles & Permissions
AWS Systems Manager (SSM) — Remote Execution
GitHub Actions — CI/CD
Kubernetes (kubeadm) — Container Orchestration
containerd — Container Runtime
📁 Repository Structure
terraform/
├── global/        # Shared resources
│   ├── IAM
│   ├── SSM Documents
│   └── Remote state config
│
├── dev/           # DEV environment
│   ├── EC2 instance
│   ├── Security group
│   ├── Kubernetes init
│   └── Terraform state
│
├── prod/          # PROD environment
│   ├── EC2 instance
│   ├── Security group
│   ├── Kubernetes init
│   └── Terraform state
│
├── scripts/
│   └── bootstrap.sh   # Kubernetes + containerd installation
