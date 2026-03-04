# ---------------------------------------------------------------------------
# Per-environment deploy role
# Jenkins agents assume this role to deploy into the environment.
# ---------------------------------------------------------------------------
data "aws_iam_policy_document" "deploy_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project_name}-agent-task"
      ]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalTag/Project"
      values   = [var.project_name]
    }
  }
}

resource "aws_iam_role" "deploy" {
  name               = "${var.project_name}-deploy-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.deploy_assume.json

  tags = {
    Environment = var.environment
  }
}

# Attach PowerUserAccess for deployments (scope down per your needs)
resource "aws_iam_role_policy_attachment" "deploy_power_user" {
  role       = aws_iam_role.deploy.name
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}

# Deny IAM mutations in prod (safety guardrail)
data "aws_iam_policy_document" "deny_iam_prod" {
  statement {
    sid    = "DenyIAMMutations"
    effect = "Deny"
    actions = [
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:AttachRolePolicy",
      "iam:DetachRolePolicy",
      "iam:PutRolePolicy",
      "iam:DeleteRolePolicy",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "deny_iam_prod" {
  count  = var.environment == "prod" ? 1 : 0
  name   = "deny-iam-mutations"
  role   = aws_iam_role.deploy.id
  policy = data.aws_iam_policy_document.deny_iam_prod.json
}
