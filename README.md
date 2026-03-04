# JenkinsPipAWS — Jenkins + ECS/Fargate on AWS

Cloud-native Jenkins platform: EC2 controller with ephemeral ECS/Fargate build agents, deployed and managed with Terraform.

## Architecture

```
┌──────────────────────────────────────────────────────────────┐
│  AWS VPC (10.0.0.0/16) — Single AZ (eu-central-1a)           │
│                                                               │
│  ┌─────────────────┐    ┌──────────────────────────────────┐  │
│  │  Public Subnet   │    │  Private Subnet                  │  │
│  │  10.0.1.0/24     │    │  10.0.11.0/24                    │  │
│  │                   │    │                                  │  │
│  │  ┌─────────────┐ │    │  ┌────────────────────────┐      │  │
│  │  │ ALB (HTTPS) │─┼────┼─▶│  Jenkins Controller    │      │  │
│  │  └─────────────┘ │    │  │  (EC2 / t3.medium)     │      │  │
│  │                   │    │  └──────────┬─────────────┘      │  │
│  └─────────────────┘ │    │             │ JNLP :50000        │  │
│                       │    │             ▼                    │  │
│                       │    │  ┌────────────────────────┐      │  │
│                       │    │  │  ECS "Jenkins-runners"  │      │  │
│                       │    │  │  (Fargate / Spot)       │      │  │
│                       │    │  │  0.5 vCPU / 1 GB        │      │  │
│                       │    │  └────────────────────────┘      │  │
│                       │    │                                  │  │
│                       │    │  ┌────────────────────────┐      │  │
│                       │    │  │  VPC Endpoints          │      │  │
│                       │    │  │  S3 · ECR · Logs · SSM  │      │  │
│                       │    │  └────────────────────────┘      │  │
│                       │    └──────────────────────────────────┘  │
│                                                               │
│  ┌──────────┐  ┌──────────┐  ┌───────────┐  ┌─────────────┐  │
│  │ ECR Repo │  │ KMS Key  │  │ S3 + DDB  │  │ Lambda      │  │
│  └──────────┘  └──────────┘  └───────────┘  │ Scale-to-0  │  │
│                               (remote state) └─────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## Directory Structure

```
terraform/
├── 00-bootstrap/           # Remote state (S3+DynamoDB), VPC, KMS
├── 01-jenkins-platform/    # ALB, ACM, Route53, EC2 controller, IAM
├── 02-agents/              # ECS Fargate cluster, ECR, task definitions
├── 03-app-infra/           # Per-env deploy roles + workspace config
└── modules/
    ├── vpc/                # VPC with public/private subnets + NAT
    ├── ecs-cluster/        # ECS Fargate cluster module
    └── jenkins-agent-task/ # Reusable agent task definition module

docker/
└── jenkins-agent/          # Dockerfile (Terraform, AWS CLI, tflint, checkov)

Jenkinsfile                 # Example pipeline for deploying app infra
```

## Deployment Order

### 1. Bootstrap (one-time)

```bash
cd terraform/00-bootstrap
terraform init
terraform apply -var="project_name=jenkins-ecs"

# After first apply, uncomment the S3 backend in providers.tf, then:
terraform init -migrate-state
```

### 2. Jenkins Platform

```bash
cd terraform/01-jenkins-platform
terraform init -backend-config="bucket=jenkins-ecs-terraform-state" \
               -backend-config="region=eu-central-1" \
               -backend-config="dynamodb_table=jenkins-ecs-terraform-locks" \
               -backend-config="encrypt=true"
terraform apply \
  -var="domain_name=example.com" \
  -var="jenkins_hostname=jenkins.example.com"
```

### 3. Build & Push Agent Image

```bash
# Authenticate to ECR
aws ecr get-login-password --region eu-central-1 | \
  docker login --username AWS --password-stdin <ACCOUNT_ID>.dkr.ecr.eu-central-1.amazonaws.com

# Build and push
cd docker/jenkins-agent
docker build -t jenkins-ecs/jenkins-agent .
docker tag jenkins-ecs/jenkins-agent:latest <ACCOUNT_ID>.dkr.ecr.eu-central-1.amazonaws.com/jenkins-ecs/jenkins-agent:latest
docker push <ACCOUNT_ID>.dkr.ecr.eu-central-1.amazonaws.com/jenkins-ecs/jenkins-agent:latest
```

### 4. Agents Layer

```bash
cd terraform/02-agents
terraform init -backend-config="bucket=jenkins-ecs-terraform-state" \
               -backend-config="region=eu-central-1" \
               -backend-config="dynamodb_table=jenkins-ecs-terraform-locks" \
               -backend-config="encrypt=true"
terraform apply
```

### 5. App Infrastructure (per environment)

```bash
cd terraform/03-app-infra
terraform init -backend-config=envs/dev.backend.hcl
terraform apply -var="environments=[\"dev\",\"stage\",\"prod\"]"
```

## Jenkins ECS Plugin Configuration

After Jenkins is running, install the **Amazon Elastic Container Service (ECS) / Fargate** plugin and configure:

| Setting             | Value                                            |
|---------------------|--------------------------------------------------|
| ECS Cluster ARN     | Output from `02-agents`                          |
| Region              | `eu-central-1`                                   |
| Task Definition     | `jenkins-ecs-agent`                              |
| Subnets             | Private subnets from bootstrap                   |
| Security Group      | Agent SG from `02-agents`                        |
| Assign Public IP    | `DISABLED`                                       |
| Launch Type         | `FARGATE`                                        |

## Per-Environment Deploy Roles

Jenkins agents assume a dedicated IAM role per environment:
- `jenkins-ecs-deploy-dev`
- `jenkins-ecs-deploy-stage`
- `jenkins-ecs-deploy-prod` (IAM mutations denied)

## Agent Sizing

| Setting | Default | Notes |
|---------|---------|-------|
| CPU     | 512 (0.5 vCPU) | Minimum viable for build agents |
| Memory  | 1024 MiB (1 GB) | Paired with 512 CPU |

Adjust via `agent_cpu` and `agent_memory` variables in `02-agents/`.

## Monthly Cost Estimation (eu-central-1)

Estimated on-demand pricing as of early 2026. Controller runs Mon–Fri 07:00–19:00 UTC (scale-to-zero enabled). Agents are ephemeral (~110 task-hours/month ≈ 20 builds/day × 15 min).

| Component | Spec | Monthly Cost |
|---|---|---:|
| EC2 — Jenkins controller | t3.medium, ~260 h/mo (weekdays only) | $12.06 |
| ALB | Hourly + ~1 LCU avg | $24.24 |
| VPC Interface Endpoints | 4 endpoints × 1 AZ × $0.011/h | $32.12 |
| ECS Fargate agents | ~22 h on-demand + ~88 h Spot (70% off) | $1.37 |
| ECR | ~2.5 GB image storage | $0.25 |
| CloudWatch Logs + Alarm | ~5 GB ingestion, 10-day retention | $3.75 |
| KMS | 1 key + API calls | $1.03 |
| Route 53 | 1 hosted zone + queries | $0.90 |
| Lambda (scale-to-zero) | ~44 invocations/mo | Free tier |
| ACM | Certificate | Free |
| S3 + DynamoDB | State files + locking | < $0.20 |
| **Total** | | **~$76/mo** |

### Cost breakdown

```
VPC Endpoints  █████████████████████████  42%  ($32.12)
ALB            ████████████████           32%  ($24.24)
EC2            ████████                   16%  ($12.06)
Other          ██████                     10%  ($7.50)
```

### Implemented cost-saving measures

- **No NAT Gateway** — removed ($41/mo saved); VPC endpoints for S3 (free gateway), ECR, CloudWatch Logs, and SSM route traffic directly to AWS services
- **Scale-to-zero** — Lambda + EventBridge automatically stops the controller at 19:00 UTC and starts it at 07:00 UTC on weekdays (~65% EC2 savings, ~$22/mo saved vs 24/7)
- **Single AZ** — all resources in `eu-central-1a` to minimize cross-AZ data transfer and endpoint costs
- **Fargate Spot** — 80/20 Spot/On-demand split; Spot tasks are ~70% cheaper
- **CloudWatch CPU alarm** — alerts when controller CPU > 80% for 15 min to help right-size before performance degrades
