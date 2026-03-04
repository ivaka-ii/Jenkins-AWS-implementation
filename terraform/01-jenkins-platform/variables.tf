variable "aws_region" {
  type    = string
  default = "eu-central-1"
}

variable "project_name" {
  type    = string
  default = "jenkins-ecs"
}

variable "controller_instance_type" {
  description = "EC2 instance type for Jenkins controller"
  type        = string
  default     = "t3.medium"
}

variable "controller_key_name" {
  description = "SSH key pair name for Jenkins controller"
  type        = string
  default     = ""
}

variable "controller_ami_id" {
  description = "AMI ID for Jenkins controller (Amazon Linux 2023). Leave empty for latest AL2023."
  type        = string
  default     = ""
}

variable "jenkins_admin_password" {
  description = "Initial admin password for Jenkins (stored in SSM)"
  type        = string
  sensitive   = true
  default     = ""
}
