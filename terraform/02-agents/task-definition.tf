# ---------------------------------------------------------------------------
# ECS Task Definition — Jenkins Agent
# ---------------------------------------------------------------------------
resource "aws_ecs_task_definition" "jenkins_agent" {
  family                   = "${var.project_name}-agent"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.agent_cpu
  memory                   = var.agent_memory
  execution_role_arn       = aws_iam_role.agent_execution.arn
  task_role_arn            = aws_iam_role.agent_task.arn

  container_definitions = jsonencode([
    {
      name      = "jenkins-agent"
      image     = "${aws_ecr_repository.jenkins_agent.repository_url}:latest"
      essential = true

      # JNLP agent — Jenkins ECS plugin injects JENKINS_URL, JENKINS_SECRET, JENKINS_AGENT_NAME
      environment = [
        { name = "JENKINS_WEB_SOCKET", value = "true" },
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.agents.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "agent"
        }
      }
    }
  ])

  tags = { Name = "${var.project_name}-agent" }
}
