
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
