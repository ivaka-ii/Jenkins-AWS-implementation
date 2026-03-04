terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    # Configure via backend.hcl or -backend-config flags
    key = "jenkins-platform/terraform.tfstate"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = var.project_name
      Layer     = "jenkins-platform"
      ManagedBy = "terraform"
    }
  }
}

# Read outputs from bootstrap layer
data "terraform_remote_state" "bootstrap" {
  backend = "s3"
  config = {
    bucket = "${var.project_name}-terraform-state"
    key    = "bootstrap/terraform.tfstate"
    region = var.aws_region
  }
}
