
#
# Azure Creds
#

locals {
  azure_workspace_ids = [
    for workspace_id in {
      for name, resource in tfe_workspace.workspace : name => resource.id
      if local.workspaces[name].creds == "azure"
    } : workspace_id
  ]

}

variable "azure_creds_arm_display_name" {
  type = string
}

variable "azure_creds_arm_subscription_id" {
  type = string
}

module "azure-creds" {
  source = "git@github.com:hashi-strawb/terraform-tfe-azure-variable-sets.git"

  organization  = var.tfe_org
  workspace_ids = local.azure_workspace_ids

  arm_display_name    = var.azure_creds_arm_display_name
  arm_subscription_id = var.azure_creds_arm_subscription_id
}
