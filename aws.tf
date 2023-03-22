
#
# AWS Creds
#

provider "aws" {
  default_tags {
    tags = {
      Name      = "StrawbTest"
      Owner     = "lucy.davinhart@hashicorp.com"
      Purpose   = "AWS Credentials for FancyCorp Org"
      TTL       = "24h"
      Terraform = "true"
      Source    = "https://github.com/FancyCorp-Demo/tfc-org-setup"
      Workspace = terraform.workspace
    }
  }
}

module "aws-oidc-provider" {
  source = "hashi-strawb/tfc-dynamic-creds-provider/aws"
  create = false # I already have one in the account from another TFC org
}

locals {
  aws_workspaces = {
    for k, v in local.workspaces : k => v
    if contains(v.creds, "aws")
  }
}


module "aws-creds" {
  source = "hashi-strawb/tfc-dynamic-creds-workspace/aws"

  for_each = local.aws_workspaces

  oidc_provider_arn = module.aws-oidc-provider.oidc_provider.arn

  tfc_organization_name = var.tfe_org
  tfc_workspace_name    = each.key
  tfc_workspace_id      = tfe_workspace.workspace[each.key].id
  tfc_workspace_project = each.value.project
}

// TODO: Create Project-Level AWS Creds
// TODO: Create Project-Level AWS Creds VarSet
// maybe do that in https://github.com/FancyCorp-Demo/nocode-creds-bootstrap
