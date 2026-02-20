# AWS Cloud Engineering Learning Journey

**Status:** Active learner transitioning to cloud engineering  
**Progress:** Week 4 of planned 24-week curriculum completed  
**Focus:** Hands-on practice with AWS services and infrastructure patterns

---

## Weekly Progress

### Week 1: AWS Fundamentals
**Topics Covered:**
- AWS account setup, IAM user configuration, MFA
- EC2 basics (launch, connect, terminate)
- S3 bucket operations
- Introduction to VPC concepts
- AWS CLI setup and basic commands

**Lab Projects:**
- Static website hosted on S3
- Basic EC2 web server

---

### Week 2: Multi-Tier Architecture
**Topics Covered:**
- RDS managed database setup
- Application Load Balancer configuration
- Auto Scaling Groups
- Security group rules and dependencies
- Deploying Flask application with MySQL backend

**Lab Projects:**
- Three-tier web application (ALB → EC2 → RDS)
- Auto Scaling configuration for basic self-healing

**Learning Note:** Struggled with security group chaining initially but understood the concept through practice.

---

### Week 3: VPC Design & Infrastructure as Code
**Topics Covered:**
- Custom VPC creation (public and private subnets)
- NAT Gateway for private subnet internet access
- Bastion host access pattern
- AWS CLI for resource management
- Introduction to Terraform

**Lab Projects:**
- Multi-AZ VPC with public/private subnet architecture
- Basic Terraform configurations for VPC resources

**Learning Note:** Terraform significantly reduced deployment time compared to manual methods. Still building comfort with HCL syntax.

---

### Week 4: Containerization & Orchestration
**Topics Covered:**
- Docker fundamentals (containers vs VMs, image building)
- Dockerfile optimization (layer caching)
- AWS ECR (private container registry)
- AWS ECS with Fargate (serverless container compute)
- Application Load Balancer with container targets
- Health checks and service auto-healing

**Lab Projects:**
- Containerized Python/Flask application
- ECS service deployment with load balancing
- Multi-container setup across availability zones

**Challenges Encountered:**
- Platform compatibility (Apple Silicon → AWS AMD64)
- Network configuration for ECR access
- Security group configuration between ALB and ECS tasks
- Health check endpoint implementation
- Approximately 17 distinct issues debugged and resolved

**Time Investment:** ~16 hours over 6 days  
**Cost:** ~$1.02 (learned importance of stopping resources!)

**Learning Note:** Most challenging week so far. Console-first approach helped build mental models before CLI automation. Troubleshooting experience valuable despite frustration.

---

## Current Skill Level

**Cloud Platforms:**
- AWS: Gaining practical experience with core services
- GCP: Basic familiarity

**Services Practiced:**
- Compute: EC2, ECS, Fargate
- Storage: S3, RDS
- Networking: VPC, subnets, ALB, security groups
- Container: ECR, ECS
- Monitoring: CloudWatch Logs (basic usage)

**Tools:**
- Docker: Building images, understanding layer optimization
- Terraform: Basic configurations, still learning
- AWS CLI: Growing comfort with commands
- Git/GitHub: Version control for learning artifacts

**Development:**
- Python: Basic Flask applications
- Bash: Simple automation scripts

**Areas for Improvement:**
- Infrastructure as Code (Terraform proficiency)
- Cost optimization strategies
- Advanced networking concepts
- Security best practices
- Monitoring and observability

---

## Certifications

- AWS Cloud Practitioner (expired 2026 - planning to renew)
- GCP Associate Cloud Engineer (valid through June 2027)

---

## Planned Next Steps

**Immediate (Week 5):**
- CI/CD pipelines OR Kubernetes basics
- Building on container knowledge while fresh

**Short-term (Weeks 6-10):**
- Monitoring and observability deep dive
- Serverless architecture (Lambda, API Gateway)
- Security hardening
- Advanced networking

**Long-term (Weeks 11-24):**
- Production-ready patterns
- Multi-region deployments
- Certification preparation (AWS Solutions Architect Associate)
- Real-world project portfolio

---

## Learning Approach

**Philosophy:** Struggle leads to understanding. Manual first, automation second.

**Methods:**
- Hands-on labs (primary learning method)
- Console exploration before CLI commands
- Documenting issues and solutions
- Building incrementally (small working pieces → complex systems)
- Cost-conscious experimentation

**Tracking:**
- All code and configurations saved in this repository
- README updates after each week
- Detailed notes on challenges and solutions

---

## Notes

This repository documents my transition from data entry professional to cloud engineer. All projects are hands-on labs - no copy/paste tutorials. Learning includes both successes and failures (documented for future reference).

**Repository Purpose:** Personal learning journal and portfolio of practical experience.

**Current Status:** Actively learning, making mistakes, debugging, and improving.