
#
# Create Credentials
# (This might become a submodule in future)
#

/*
resource "tfe_team" "manage-workspaces" {
  name         = "Manage Workspaces"
  organization = var.tfe_org
  organization_access {
    manage_workspaces = true


    # Workaround for a bug
    # TODO: Remove once the bug is fixed
    manage_policies = true
  }
}
*/

// TODO: For some reason, while this does give the abiltiy to create variables
// you cannot read them afterwards...
// so use the owner team instead (for now)

data "tfe_team" "owners" {
  name         = "owners"
  organization = var.tfe_org
}

resource "tfe_team_token" "manage-workspaces" {
  #  team_id = tfe_team.manage-workspaces.id
  team_id = data.tfe_team.owners.id
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
