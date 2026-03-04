output "ecs_cluster_arn" {
  description = "ECS cluster ARN"
  value       = aws_ecs_cluster.jenkins.arn
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.jenkins.name
}

output "ecr_repository_url" {
  description = "ECR repository URL for Jenkins agent image"
  value       = aws_ecr_repository.jenkins_agent.repository_url
}

output "agent_task_definition_arn" {
  description = "Agent task definition ARN"
  value       = aws_ecs_task_definition.jenkins_agent.arn
}

output "agent_task_role_arn" {
  description = "Agent task IAM role ARN"
  value       = aws_iam_role.agent_task.arn
}

output "agent_execution_role_arn" {
  description = "Agent execution IAM role ARN"
  value       = aws_iam_role.agent_execution.arn
}

output "agent_security_group_id" {
  description = "Agent security group ID"
  value       = aws_security_group.agent.id
}

output "agent_subnets" {
  description = "Subnets used for agent tasks"
  value       = local.private_subnet_ids
}

output "agent_log_group" {
  description = "CloudWatch log group for agents"
  value       = aws_cloudwatch_log_group.agents.name
}
