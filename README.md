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

### Week 5: Terraform — Codifying ECS Stack
**Topics Covered:**
- Terraform project structure (providers, variables, outputs, main)
- Terraform state management
- Resource dependency graphs and references
- VPC and networking layer in HCL
- Security group chaining in Terraform
- ECS Fargate + ALB fully defined as code
- IAM roles via Terraform
- Infrastructure destroy and rebuild cycle

**Lab Projects:**
- Complete ECS Fargate stack deployed entirely by Terraform
- Full destroy/rebuild cycle proving infrastructure reproducibility

**Learning Note:** Same infrastructure as Week 4 built in a fraction of the time. Terraform state clicked through practice, not theory — existing resources showed zero changes on reapply, only new additions were touched.

---

### Week 6: CI/CD — Automating ECS Deployments with GitHub Actions
**Topics Covered:**
- GitHub Actions workflow structure (triggers, jobs, steps, runners)
- GitHub Secrets for secure credential management
- AWS authentication from pipeline using IAM access keys
- Docker build and ECR push automated on every code push
- Image tagging strategy: commit SHA for traceability + latest for ECS
- ECS task definition revision pattern (why you can't edit in place)
- Rolling deployments with zero downtime
- Test-driven pipeline: pytest blocking bad deployments before build
- Failure handling with conditional steps

**Lab Projects:**
- Full CI/CD pipeline: git push → tests → Docker build → ECR push → ECS redeploy
- Deliberately broken tests proving pipeline stops bad code reaching production

**Learning Note:** The labs felt short compared to previous weeks but the complexity was in connecting everything built since Week 1: GitHub, Docker, ECR, ECS, IAM all working together automatically. The "aha moment" was seeing a text change in app.py appear live in the browser without touching AWS console once.

---

## Week 7: CloudWatch Monitoring & Observability

### What I Built
- CloudWatch dashboard: ECS CPU, memory, ALB request count, 
  response time, healthy host count
- SNS email alerts for unhealthy hosts, high CPU, 5XX errors
- CloudWatch Logs Insights queries for traffic analysis 
  and error detection
- Log-based custom metric (4XXErrorCount) bridging 
  logs → metrics → dashboard
- Auto scaling policies: CPU > 70% adds tasks, 
  CPU < 30% removes tasks
- All monitoring infrastructure codified in Terraform

### What I Learned
- Metrics answer WHAT broke, logs answer WHY it broke
- Alarm evaluation periods prevent false alerts (2/3 vs 1/1)
- Missing data treatment is context dependent 
  (breaching for hosts, notBreaching for CPU)
- Auto scaling needs 3 parts: target + policy + alarm
- Scale up fast (60s cooldown), scale down slow (300s cooldown)
- brew > pip on macOS (lesson learned the hard way)

### What Surprised Me
- CloudWatch keeps metrics from destroyed resources for 15 months
- 100 concurrent users barely registers on a simple Flask app
- Auto scaling scaled to 4 tasks (max) before I could blink
- Infrastructure fixing itself without human involvement 
  is genuinely satisfying


---

## Week 8: Secrets Management + RDS Integration

**Architecture:** 4-tier stack — networking + compute + database + secrets

**What I built:**
- AWS Secrets Manager storing RDS credentials - never in code or plaintext env vars
- AWS Parameter Store for non-sensitive configuration
- RDS MySQL in private subnets - not publicly accessible, reachable only from ECS
- DB subnet group spanning 2 AZs - AWS requirement even for single-AZ deployment
- ECS task definition secrets block - credentials injected at container startup by ECS agent
- Least-privilege IAM execution role scoped to week8/* secrets only
- Security group chain: internet → ALB SG → ECS SG → RDS SG (identity-based, not CIDR)
- Terraform data source reading password from Secrets Manager at apply time
- CI/CD pipeline updated - git push triggers automatic build and ECS redeployment

**Key concepts learned:**
- Secrets Manager vs Parameter Store - sensitivity and rotation are the deciding factors
- Envelope encryption — secrets encrypted with KMS data key, never stored in plaintext
- ECS execution role vs task role — agent permissions vs application permissions
- Secret versioning — AWSCURRENT, AWSPREVIOUS, AWSPENDING and why they exist
- Rotation flow — four Lambda steps, zero application code changes needed
- Terraform state file risk — tfstate contains plaintext secrets, must never be committed
- `.endpoint` vs `.address` in Terraform — endpoint includes port, address is hostname only

**Stack:** AWS Secrets Manager · Parameter Store · RDS MySQL 8.0 · ECS Fargate · ALB · 
Terraform · GitHub Actions · Flask · Docker · ECR

---

## Week 9: HTTPS with ACM Certificates

**Live at:** https://pavlopopok.click

### What I built
- Registered personal domain (pavlopopok.click) via Namecheap
- Created Route 53 hosted zone manually, pointed Namecheap DNS to Route 53 nameservers
- Requested free SSL certificate from AWS Certificate Manager (ACM)
- DNS validation via Route 53 CNAME record — auto-renews forever with zero maintenance
- ALB HTTPS listener on port 443 with TLS 1.3 policy (ELBSecurityPolicy-TLS13-1-2-2021-06)
- HTTP→HTTPS permanent redirect (301) on port 80
- Route 53 alias record pointing domain to ALB — no hardcoded IPs
- CI/CD pipeline updated — deployment verification now uses HTTPS domain endpoint

### Key concepts learned
- **TLS termination at the ALB** — ECS containers keep receiving plain HTTP internally, the ALB handles encryption/decryption with browsers using the ACM certificate
- **ACM DNS validation** — proving domain ownership by adding a CNAME record ACM can query; as long as that record stays in Route 53, ACM auto-renews the certificate forever
- **Route 53 alias records vs CNAME** — alias is a Route 53-specific feature that points to another AWS resource by DNS name instead of IP; free, auto-updates if ALB IPs change, works on root domain (plain CNAME can't do that)
- **HTTP 301 vs 302** — 301 is permanent redirect, browsers cache it and go straight to HTTPS on future visits without touching port 80
- **Registrar vs hosted zone** — registrar (Namecheap) holds your domain reservation; hosted zone (Route 53) answers DNS queries for it; you can use different providers for each by updating nameservers
- **ACM certificate region** — certificate must be in the same region as the resource using it; requesting in the wrong region silently fails at ALB attachment
- **Wildcard SAN** — one certificate covers root domain and all subdomains via `*.pavlopopok.click`; always request alongside root at no extra cost

### Gotchas documented
- Route 53 domain registration blocked on Free Tier accounts — pivot to Namecheap + manual hosted zone
- ALB HTTPS listener `default_action` must be `forward`, not `redirect` — redirect on port 443 creates an infinite loop
- HTTP listener `target_group_arn` must be removed when changing action to `redirect` — Terraform errors if both are present
- Security group port 443 rule must be added explicitly — HTTPS traffic is blocked at network level without it
- Pipeline hardcoded cluster/service/task names override `env` block — always check step-level `env` for conflicts

---

## Week 10: Advanced Terraform — Modules and Remote State

Architecture: Same stack as Week 9 — networking + compute + ALB + HTTPS. Code quality upgraded from flat to modular.

**What I built:**
* Networking module — VPC, subnets, IGW, route tables, security groups as a reusable component
* ALB module — load balancer, target group, HTTP→HTTPS redirect, HTTPS listener, Route 53 alias record
* ECS module — cluster, task definition, IAM execution role, Fargate service, CloudWatch log group
* Root module wiring all three together via module outputs — no direct cross-module resource references
* S3 bucket for remote state — versioned, encrypted, public access blocked
* DynamoDB table for state locking — prevents concurrent apply conflicts
* State migrated from local laptop to S3 with `terraform init -migrate-state`
* Staging configuration via `staging.tfvars` — same modules, different variable values

**Key concepts learned:**
* Terraform modules — reusable folders with their own variables, resources and outputs; root module is the orchestrator
* Module outputs as the only communication channel — modules never reference each other's resources directly
* Remote backend — tfstate in S3 means infrastructure is no longer tied to one machine
* State locking — DynamoDB ensures only one `terraform apply` runs at a time
* `.tfvars` files — override variable defaults at runtime, enabling staging/production pattern from one codebase
* `terraform init -migrate-state` — moves existing local state to a new backend without losing resource tracking
* Same modules deployable multiple times with different configurations — one source of truth

**


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

- GCP Associate Cloud Engineer (valid through June 2027)

---

## Planned Next Steps

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
