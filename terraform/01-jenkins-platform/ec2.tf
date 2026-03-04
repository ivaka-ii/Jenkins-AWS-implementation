# ---------------------------------------------------------------------------
# EC2 — Jenkins Controller (public subnet + Elastic IP)
# ---------------------------------------------------------------------------
data "aws_ssm_parameter" "al2023_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-6.1-x86_64"
}

locals {
  ami_id = var.controller_ami_id != "" ? var.controller_ami_id : data.aws_ssm_parameter.al2023_ami.value
}

resource "aws_instance" "jenkins_controller" {
  ami                    = local.ami_id
  instance_type          = var.controller_instance_type
  subnet_id              = local.public_subnet_ids[0]
  iam_instance_profile   = aws_iam_instance_profile.jenkins_controller.name
  vpc_security_group_ids = [aws_security_group.controller.id]
  key_name               = var.controller_key_name != "" ? var.controller_key_name : null

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true
    kms_key_id  = local.kms_key_arn
  }

  user_data = base64encode(templatefile("${path.module}/templates/user-data.sh", {
    aws_region   = var.aws_region
    project_name = var.project_name
  }))

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required" # IMDSv2
  }

  tags = { Name = "${var.project_name}-controller" }
}

# Elastic IP for stable public access
resource "aws_eip" "controller" {
  domain   = "vpc"
  instance = aws_instance.jenkins_controller.id
  tags     = { Name = "${var.project_name}-controller-eip" }
}
