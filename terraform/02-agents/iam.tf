# ---------------------------------------------------------------------------
# IAM — ECS Task Execution Role (pulling images, writing logs)
# ---------------------------------------------------------------------------
data "aws_iam_policy_document" "ecs_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "agent_execution" {
  name               = "${var.project_name}-agent-execution"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume.json
}

resource "aws_iam_role_policy_attachment" "agent_execution" {
  role       = aws_iam_role.agent_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Allow pulling from our ECR repo (KMS decrypt)
data "aws_iam_policy_document" "execution_extras" {
  statement {
    sid       = "KMSDecrypt"
    actions   = ["kms:Decrypt"]
    resources = [local.kms_key_arn]
  }
}

resource "aws_iam_role_policy" "execution_extras" {
  name   = "execution-extras"
  role   = aws_iam_role.agent_execution.id
  policy = data.aws_iam_policy_document.execution_extras.json
}

# ---------------------------------------------------------------------------
# IAM — ECS Task Role (what the agent container can do at runtime)
# ---------------------------------------------------------------------------
resource "aws_iam_role" "agent_task" {
  name               = "${var.project_name}-agent-task"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume.json
}

# Agents can assume per-environment deploy roles
data "aws_iam_policy_document" "agent_task_permissions" {
  statement {
    sid     = "AssumeDeployRoles"
    actions = ["sts:AssumeRole"]
    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project_name}-deploy-*"
    ]
  }

  # S3 access for Terraform state
  statement {
    sid = "TerraformState"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket",
    ]
    resources = [
      "arn:aws:s3:::${var.project_name}-terraform-state",
      "arn:aws:s3:::${var.project_name}-terraform-state/*",
    ]
  }

  # DynamoDB for state locking
  statement {
    sid = "TerraformLocks"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem",
    ]
    resources = [
      "arn:aws:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/${var.project_name}-terraform-locks"
    ]
  }

  # CloudWatch Logs
  statement {
    sid = "Logs"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["${aws_cloudwatch_log_group.agents.arn}:*"]
  }
}

resource "aws_iam_role_policy" "agent_task" {
  name   = "agent-task-permissions"
  role   = aws_iam_role.agent_task.id
  policy = data.aws_iam_policy_document.agent_task_permissions.json
}
