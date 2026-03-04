# ---------------------------------------------------------------------------
# Security Groups
# ---------------------------------------------------------------------------

# Controller SG — HTTP 8080 from internet + JNLP from VPC
resource "aws_security_group" "controller" {
  name_prefix = "${var.project_name}-ctrl-"
  description = "Jenkins controller"
  vpc_id      = local.vpc_id

  ingress {
    description = "Jenkins UI"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # JNLP port for ECS agents
  ingress {
    description = "JNLP agents"
    from_port   = 50000
    to_port     = 50000
    protocol    = "tcp"
    cidr_blocks = [local.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle { create_before_destroy = true }
  tags = { Name = "${var.project_name}-controller" }
}
