variable "aws_region" {
  type    = string
  default = "eu-central-1"
}

variable "project_name" {
  type    = string
  default = "jenkins-ecs"
}

variable "environments" {
  description = "List of deployment environments"
  type        = list(string)
  default     = ["dev", "stage", "prod"]
}
