# ---------------------------------------------------------------------------
# IAM — Jenkins Controller
# ---------------------------------------------------------------------------
data "aws_iam_policy_document" "ec2_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "jenkins_controller" {
  name               = "${var.project_name}-controller"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
}

resource "aws_iam_instance_profile" "jenkins_controller" {
  name = "${var.project_name}-controller"
  role = aws_iam_role.jenkins_controller.name
}

# Allow controller to manage ECS tasks (for Jenkins ECS plugin)
data "aws_iam_policy_document" "controller_permissions" {
  # ECS agent management
  statement {
    sid = "ECSAgentManagement"
    actions = [
      "ecs:RegisterTaskDefinition",
      "ecs:DeregisterTaskDefinition",
      "ecs:ListClusters",
      "ecs:DescribeClusters",
      "ecs:DescribeContainerInstances",
      "ecs:ListTaskDefinitions",
      "ecs:DescribeTaskDefinition",
      "ecs:DescribeTasks",
      "ecs:ListTasks",
      "ecs:RunTask",
      "ecs:StopTask",
    ]
    resources = ["*"]
  }

  # Pass role to ECS tasks
  statement {
    sid     = "PassRole"
    actions = ["iam:PassRole"]
    resources = [
      aws_iam_role.jenkins_controller.arn,
      "arn:aws:iam::*:role/${var.project_name}-agent-*",
    ]
  }

  # ECR pull
  statement {
    sid = "ECR"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
    ]
    resources = ["*"]
  }

  # CloudWatch Logs
  statement {
    sid = "Logs"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
    ]
    resources = ["*"]
  }

  # SSM for secrets
  statement {
    sid = "SSM"
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:GetParametersByPath",
    ]
    resources = ["arn:aws:ssm:${var.aws_region}:*:parameter/${var.project_name}/*"]
  }
}

resource "aws_iam_role_policy" "controller" {
  name   = "controller-permissions"
  role   = aws_iam_role.jenkins_controller.id
  policy = data.aws_iam_policy_document.controller_permissions.json
}

# SSM managed instance for Session Manager access
resource "aws_iam_role_policy_attachment" "ssm_managed" {
  role       = aws_iam_role.jenkins_controller.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
