# ---------------------------------------------------------------------------
# ECS Cluster (Fargate)
# ---------------------------------------------------------------------------
resource "aws_ecs_cluster" "jenkins" {
  name = "Jenkins-runners"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = { Name = "${var.project_name}-agents" }
}

# Only Fargate — no EC2 capacity providers needed
resource "aws_ecs_cluster_capacity_providers" "jenkins" {
  cluster_name       = aws_ecs_cluster.jenkins.name
  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight            = 4
    base              = 0
  }

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 1
    base              = 1 # at least 1 on-demand task
  }
}

# CloudWatch log group
resource "aws_cloudwatch_log_group" "agents" {
  name              = "/ecs/${var.project_name}-agents"
  retention_in_days = var.agent_log_retention_days

  tags = { Name = "${var.project_name}-agents" }
}

# Security group for agent tasks
resource "aws_security_group" "agent" {
  name_prefix = "${var.project_name}-agent-"
  description = "Jenkins ECS agents"
  vpc_id      = local.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle { create_before_destroy = true }
  tags = { Name = "${var.project_name}-agent" }
}

# Allow agents → controller JNLP (port 50000)
resource "aws_security_group_rule" "agent_to_controller_jnlp" {
  type                     = "ingress"
  from_port                = 50000
  to_port                  = 50000
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.agent.id
  security_group_id        = local.controller_sg_id
  description              = "JNLP from ECS agents"
}
