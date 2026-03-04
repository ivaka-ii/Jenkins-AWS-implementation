locals {
  vpc_id             = data.terraform_remote_state.bootstrap.outputs.vpc_id
  vpc_cidr           = data.terraform_remote_state.bootstrap.outputs.vpc_cidr_block
  private_subnet_ids = data.terraform_remote_state.bootstrap.outputs.private_subnet_ids
  kms_key_arn        = data.terraform_remote_state.bootstrap.outputs.kms_key_arn
  controller_sg_id   = data.terraform_remote_state.jenkins_platform.outputs.controller_sg_id
}

data "aws_caller_identity" "current" {}
