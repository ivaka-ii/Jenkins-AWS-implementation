variable "aws_region" {
  type    = string
  default = "eu-central-1"
}

variable "project_name" {
  type    = string
  default = "jenkins-ecs"
}

variable "environment" {
  description = "Deployment environment (e.g. dev, stage, prod)"
  type        = string
  default     = "dev"
}
