# ---------------------------------------------------------------------------
# ECR Repository — Jenkins Agent Image
# ---------------------------------------------------------------------------
resource "aws_ecr_repository" "jenkins_agent" {
  name                 = "${var.project_name}/jenkins-agent"
  image_tag_mutability = "MUTABLE"
  force_delete         = false

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = local.kms_key_arn
  }

  tags = { Name = "${var.project_name}-jenkins-agent" }
}

# Lifecycle policy — keep last 5 images
resource "aws_ecr_lifecycle_policy" "jenkins_agent" {
  repository = aws_ecr_repository.jenkins_agent.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 5 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 5
      }
      action = { type = "expire" }
    }]
  })
}
