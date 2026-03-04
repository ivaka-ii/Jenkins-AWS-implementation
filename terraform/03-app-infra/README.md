# ---------------------------------------------------------------------------
# Per-environment backend configuration
# Use: terraform init -backend-config=envs/<env>.backend.hcl
# ---------------------------------------------------------------------------

# envs/dev.backend.hcl
# bucket         = "jenkins-ecs-terraform-state"
# key            = "app/dev/terraform.tfstate"
# region         = "eu-central-1"
# dynamodb_table = "jenkins-ecs-terraform-locks"
# encrypt        = true
