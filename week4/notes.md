# Week 4: Docker & AWS ECS

**Containerized Flask application on AWS ECS with Fargate**

## What I Built
- Dockerized Python/Flask app
- Deployed to AWS ECS with Fargate serverless
- Application Load Balancer with 2 containers
- Auto-healing and health checks
- Multi-AZ high availability

## Stats
- **Issues resolved:** 17 (platform, networking, IAM, health checks)
- **Cost:** ~$1.02
- **Tech:** Docker, ECR, ECS, Fargate, ALB, CloudWatch

## Key Learnings
1. ARM64 -> AMD64 cross-compilation for Apple Silicon
2. Public subnet + Public IP needed for ECR access
3. Health check endpoint implementation (/api/health)
4. Load balancer connection persistence
5. Console for learning, CLI for reliability

