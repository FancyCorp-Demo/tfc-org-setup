
terraform {
  required_providers {
    terracurl = {
      source = "devops-rob/terracurl"
    }
  }
}

#
# Create AWS role for the project to Assume
#

resource "aws_iam_role" "project_role" {

  name = "tfc-${var.tfc_organization_name}-${local.tfc_project_nospaces}"

  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Effect": "Allow",
     "Principal": {
       "Federated": "${var.oidc_provider_arn}"
     },
     "Action": "sts:AssumeRoleWithWebIdentity",
     "Condition": {
       "StringEquals": {
         "app.terraform.io:aud": "${one(var.oidc_provider_client_id_list)}"
       },
       "StringLike": {
         "app.terraform.io:sub": "organization:${var.tfc_organization_name}:project:${var.tfc_project_name}:workspace:*:run_phase:*"
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

resource "tfe_variable_set" "creds" {
  name         = "AWS Dynamic Creds: ${var.tfc_project_name} Project"
  description  = "AWS Auth & Role details for Dynamic AWS Creds"
  organization = var.tfc_organization_name
}


resource "tfe_variable" "workspace_enable_aws_provider_auth" {
  key      = "TFC_AWS_PROVIDER_AUTH"
  value    = "true"
  category = "env"

  description = "Enable the Workload Identity integration for AWS."

  variable_set_id = tfe_variable_set.creds.id
}

resource "tfe_variable" "workspace_tfc_aws_role_arn" {
  key      = "TFC_AWS_RUN_ROLE_ARN"
  value    = aws_iam_role.project_role.arn
  category = "env"

  description = "The AWS role arn runs will use to authenticate."

  variable_set_id = tfe_variable_set.creds.id
}

# TODO: Map VarSet to Project with the TFE provider once that's possible

resource "terracurl_request" "creds_to_project" {
  name = "creds_to_project"
  url  = "https://app.terraform.io/api/v2/varsets/${tfe_variable_set.creds.id}/relationships/projects"

  method = "POST"

  headers = {
    Authorization = "Bearer ${var.tfc_token}"
    Content-Type  = "application/vnd.api+json"
  }
  response_codes = [204]

  request_body = <<EOF
{
  "data": [
    {
      "type": "projects",
      "id": "${var.tfc_project_id}"
    }
  ]
}
EOF
}
