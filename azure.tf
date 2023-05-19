
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

  source  = "hashi-strawb/tfc-dynamic-creds-workspace/azure"
  version = "0.3.0"
  #source = "./submodules/terraform-azure-tfc-dynamic-creds-workspace"

  for_each = local.azure_workspaces

  tfc_organization_name = var.tfe_org
  tfc_workspace_name    = each.key
  tfc_workspace_id      = tfe_workspace.workspace[each.key].id
  tfc_workspace_project = each.value.project

  # TODO: determine this from the workspace.yml
  azure_role_definition_name = each.key == "vault-config" ? "Owner" : "Contributor"
  azuread_graph_permissions  = each.key == "vault-config" ? ["Application.ReadWrite.OwnedBy", "AppRoleAssignment.ReadWrite.All"] : []
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

resource "tfe_project_variable_set" "azure_nocode" {
  variable_set_id = module.azure-varset-creds.varset_id

  for_each = toset([
    "Azure No-Code",
    "Azure TF OSS to TFC",
  ])

  project_id = tfe_project.projects[each.key].id
}
