
#
# Azure Creds
#

provider "azurerm" {
  features {}
}

locals {
  azure_workspaces = {
    for k, v in local.workspaces : k => v
    if contains(v.creds, "azure")
  }
}

module "azure-creds" {
  source = "./submodules/workspace-azure-creds"

  for_each = local.azure_workspaces

  tfc_organization_name = var.tfe_org
  tfc_workspace_name    = each.key
  tfc_workspace_id      = tfe_workspace.workspace[each.key].id
  tfc_workspace_project = each.value.project
}



//
// Legacy VarSet Creds: useful for no-code
//

locals {
  azure_workspace_ids = [
    for workspace_id in {
      for name, resource in tfe_workspace.workspace : name => resource.id
      if contains(local.workspaces[name].creds, "azure")
    } : workspace_id
  ]
}

variable "azure_creds_arm_display_name" {
  type = string
}

variable "azure_creds_arm_subscription_id" {
  type = string
}
module "azure-varset-creds" {
  source = "git@github.com:hashi-strawb/terraform-tfe-azure-variable-sets.git"

  organization = var.tfe_org
  //workspace_ids = local.azure_workspace_ids

  arm_display_name    = var.azure_creds_arm_display_name
  arm_subscription_id = var.azure_creds_arm_subscription_id
}




// TODO: Map varset to "Azure No-Code" Project with the TFE provider once that's possible
// maybe do that in https://github.com/FancyCorp-Demo/nocode-creds-bootstrap, as well as moving varset creation to that repo too


// https://hashicorp.slack.com/archives/C04LYC512E5/p1677791605289199

resource "terracurl_request" "azure_nocode" {
  name = "azure_nocode"
  url  = "https://app.terraform.io/api/v2/varsets/${module.azure-varset-creds.varset_id}/relationships/projects"

  method = "POST"

  headers = {
    Authorization = "Bearer ${local.tfc_token}"
    Content-Type  = "application/vnd.api+json"
  }
  response_codes = [204]

  request_body = <<EOF
{
  "data": [
    {
      "type": "projects",
      "id": "${tfe_project.projects["Azure No-Code"].id}"
    }
  ]
}
EOF
}
