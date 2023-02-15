# TODO:
# If workspace asks for HCP creds, add the varset
# https://app.terraform.io/app/fancycorp/settings/varsets/varset-953YiG2AtndV2D93
#
# e.g.
# creds:
# - aws
# - hcp:viewer



variable "hcp_viewer_varset" {
  type    = string
  default = "varset-953YiG2AtndV2D93"
}


locals {
  hcp_viewer_workspaces = {
    for k, v in local.workspaces : k => v
    if contains(v.creds, "hcp:viewer")
  }
}

resource "tfe_workspace_variable_set" "hcp_viewer" {
  for_each = local.hcp_viewer_workspaces

  variable_set_id = var.hcp_viewer_varset
  workspace_id    = tfe_workspace.workspace[each.key].id
}
