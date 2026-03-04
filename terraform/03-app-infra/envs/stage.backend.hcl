bucket         = "jenkins-ecs-terraform-state"
key            = "app/stage/terraform.tfstate"
region         = "eu-central-1"
dynamodb_table = "jenkins-ecs-terraform-locks"
encrypt        = true
