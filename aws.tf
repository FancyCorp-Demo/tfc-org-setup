
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



// TODO: In future, do this in a workspace within the org
// Workspace should create the Project, the creds,
// and should also create a "Delete" resource for any workspaces in the project

locals {
  aws_projects = {
    "AWS No-Code" : tfe_project.projects["AWS No-Code"].id
  }
}

module "aws-project-creds" {
  #source = "hashi-strawb/tfc-dynamic-creds-project/aws"
  source = "./submodules/project-aws-creds"

  # TODO: for_each this in future

  oidc_provider_arn = module.aws-oidc-provider.oidc_provider.arn

  tfc_organization_name = var.tfe_org
  tfc_project_name      = "AWS No-Code"
  tfc_project_id        = tfe_project.projects["AWS No-Code"].id

  tfc_token = local.tfc_token
}
