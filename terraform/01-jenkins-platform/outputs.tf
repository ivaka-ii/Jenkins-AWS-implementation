output "jenkins_url" {
  description = "Jenkins URL"
  value       = "http://${aws_eip.controller.public_ip}:8080"
}

output "jenkins_eip" {
  description = "Jenkins controller Elastic IP"
  value       = aws_eip.controller.public_ip
}

output "controller_instance_id" {
  description = "Jenkins controller EC2 instance ID"
  value       = aws_instance.jenkins_controller.id
}

output "controller_sg_id" {
  description = "Controller security group ID"
  value       = aws_security_group.controller.id
}

output "controller_iam_role_arn" {
  description = "Jenkins controller IAM role ARN"
  value       = aws_iam_role.jenkins_controller.arn
}
