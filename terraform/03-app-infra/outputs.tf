output "deploy_role_arns" {
  description = "Map of environment → deploy role ARN"
  value       = { for env, role in aws_iam_role.deploy : env => role.arn }
}
