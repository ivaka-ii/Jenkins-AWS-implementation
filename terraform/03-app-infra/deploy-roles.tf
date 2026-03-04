# ---------------------------------------------------------------------------
# Per-environment deploy roles
# Jenkins agents assume these roles to deploy into each environment.
# ---------------------------------------------------------------------------
data "aws_iam_policy_document" "deploy_assume" {
  for_each = toset(var.environments)

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
  for_each = toset(var.environments)

  name               = "${var.project_name}-deploy-${each.key}"
  assume_role_policy = data.aws_iam_policy_document.deploy_assume[each.key].json

  tags = {
    Environment = each.key
  }
}

# Attach PowerUserAccess for deployments (scope down per your needs)
resource "aws_iam_role_policy_attachment" "deploy_power_user" {
  for_each   = toset(var.environments)
  role       = aws_iam_role.deploy[each.key].name
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
  count  = contains(var.environments, "prod") ? 1 : 0
  name   = "deny-iam-mutations"
  role   = aws_iam_role.deploy["prod"].id
  policy = data.aws_iam_policy_document.deny_iam_prod.json
}
