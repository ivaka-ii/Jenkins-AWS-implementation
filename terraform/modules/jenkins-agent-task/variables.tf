variable "family" {
  description = "Task definition family name"
  type        = string
}

variable "image" {
  description = "Container image URI"
  type        = string
}

variable "cpu" {
  type    = number
  default = 512
}

variable "memory" {
  type    = number
  default = 1024
}

variable "execution_role_arn" {
  type = string
}

variable "task_role_arn" {
  type = string
}

variable "log_group" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "environment" {
  description = "Environment variables for the container"
  type        = list(object({ name = string, value = string }))
  default     = []
}
