output "deploy_role_arn" {
  description = "Deploy role ARN for the target environment"
  value       = aws_iam_role.deploy.arn
}
