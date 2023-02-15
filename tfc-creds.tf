
#
# Create Credentials
# (This might become a submodule in future)
#

resource "tfe_team" "manage-workspaces" {
  name         = "Manage Workspaces"
  organization = var.tfe_org
  organization_access {
    manage_workspaces = true
  }
}

resource "tfe_team_token" "manage-workspaces" {
  team_id = tfe_team.manage-workspaces.id
}


resource "tfe_variable_set" "tfc-creds" {
  name         = "TFC: Workspace Manage"
  organization = var.tfe_org
}

resource "tfe_variable" "tfc-creds" {
  key             = "TFE_TOKEN"
  value           = tfe_team_token.manage-workspaces.token
  category        = "env"
  sensitive       = true
  variable_set_id = tfe_variable_set.tfc-creds.id
}




#
# Link to workspaces
#

locals {
  tfc_creds_workspace_ids = {
    for name, resource in tfe_workspace.workspace : name => resource.id
    if contains(local.workspaces[name].creds, "tfc")
  }
}

resource "tfe_workspace_variable_set" "tfc-creds" {
  for_each        = local.tfc_creds_workspace_ids
  variable_set_id = tfe_variable_set.tfc-creds.id
  workspace_id    = each.value
}
