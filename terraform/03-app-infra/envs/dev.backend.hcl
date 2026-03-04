bucket         = "jenkins-ecs-terraform-state"
key            = "app/dev/terraform.tfstate"
region         = "eu-central-1"
dynamodb_table = "jenkins-ecs-terraform-locks"
encrypt        = true
