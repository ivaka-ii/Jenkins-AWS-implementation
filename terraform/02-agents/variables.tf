variable "aws_region" {
  type    = string
  default = "eu-central-1"
}

variable "project_name" {
  type    = string
  default = "jenkins-ecs"
}

variable "agent_cpu" {
  description = "Fargate task CPU units (256 = 0.25 vCPU, 512 = 0.5 vCPU, 1024 = 1 vCPU)"
  type        = number
  default     = 512 # 0.5 vCPU — minimum viable for build agents
}

variable "agent_memory" {
  description = "Fargate task memory in MiB (must be compatible with CPU units)"
  type        = number
  default     = 1024 # 1 GB — paired with 512 CPU
}

variable "agent_log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
}
