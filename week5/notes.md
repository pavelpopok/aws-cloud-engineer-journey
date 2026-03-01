# Week 5: ECS Fargate Stack in Terraform

A complete AWS infrastructure deployment using Terraform:
VPC, subnets, security groups, ECS Fargate cluster,
Application Load Balancer, and a Flask containerized app,
all defined as code and deployable in one command.

## Architecture
​```
Browser → ALB (port 80) → ECS Fargate (2 tasks, port 5000) → ECR image
​```
Each component lives in its own Terraform resource block,
wired together through references — no hardcoded IDs anywhere.

## Deploy
​```bash
terraform init && terraform apply
​```

## Destroy
​```bash
terraform destroy
​```

## Variables
| Name | Description | Default |
|------|-------------|---------|
| aws_region | Deployment region | eu-central-1 |
| project_name | Prefix for all resources | week5 |
| container_port | Container listening port | 5000 |
