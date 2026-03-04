terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # After first apply, migrate local state to S3:
  #   terraform init -migrate-state
  backend "s3" {
    bucket         = "jenkins-ecs-terraform-state"
    key            = "bootstrap/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "jenkins-ecs-terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = var.project_name
      Layer     = "bootstrap"
      ManagedBy = "terraform"
    }
  }
}
