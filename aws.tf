
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

resource "aws_iam_role" "org_role" {
  name = "tfc-${var.tfe_org}"

  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Effect": "Allow",
     "Principal": {
       "Federated": "${module.aws-oidc-provider.oidc_provider.arn}"
     },
     "Action": "sts:AssumeRoleWithWebIdentity",
     "Condition": {
       "StringEquals": {
         "app.terraform.io:aud": "aws.workload.identity"
       },
       "StringLike": {
         "app.terraform.io:sub": "organization:${var.tfe_org}:*"
       }
     }
   }
 ]
}
EOF

  # TODO: this is waaaaay too much access; limit it to just what's needed
  # TODO: separate policies for Plan and Apply (e.g. readonly and admin)
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AdministratorAccess"
  ]

  lifecycle {
    create_before_destroy = true
  }
}

resource "tfe_variable" "workspace_enable_aws_provider_auth" {
  for_each = local.aws_workspaces

  workspace_id = tfe_workspace.workspace[each.key].id

  key      = "TFC_AWS_PROVIDER_AUTH"
  value    = "true"
  category = "env"

  description = "Enable the Workload Identity integration for AWS."
}

resource "tfe_variable" "workspace_tfc_aws_role_arn" {
  for_each = local.aws_workspaces

  workspace_id = tfe_workspace.workspace[each.key].id

  key      = "TFC_AWS_RUN_ROLE_ARN"
  value    = aws_iam_role.org_role.arn
  category = "env"

  description = "The AWS role arn runs will use to authenticate."
}
