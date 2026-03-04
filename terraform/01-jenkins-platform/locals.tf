locals {
  vpc_id             = data.terraform_remote_state.bootstrap.outputs.vpc_id
  vpc_cidr           = data.terraform_remote_state.bootstrap.outputs.vpc_cidr_block
  public_subnet_ids  = data.terraform_remote_state.bootstrap.outputs.public_subnet_ids
  private_subnet_ids = data.terraform_remote_state.bootstrap.outputs.private_subnet_ids
  kms_key_arn        = data.terraform_remote_state.bootstrap.outputs.kms_key_arn
}
