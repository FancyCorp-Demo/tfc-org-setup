
# TODO: In future, we want to create these with TF
# (probably in the Bootstrap workspace)
variable "hcp_varsets" {
  type = map(string)
  default = {
    "hcp:viewer"      = "varset-953YiG2AtndV2D93",
    "hcp:contributor" = "varset-7BRrWLKfZx6HhfPP",
  }
}

locals {
  hcp_workspaces = {
    for k, v in local.workspaces : k => setintersection(
      tolist(v.creds),
      ["hcp:viewer", "hcp:contributor"]
    )
    if length(
      setintersection(
        tolist(v.creds),
        ["hcp:viewer", "hcp:contributor"]
      )
    ) == 1
    # TODO: ideally we'd throw a validation error if more than one hcp: cred is used here
  }

  hcp_workspaces_varset = {
    for k, v in local.hcp_workspaces : k => var.hcp_varsets[one(v)]
  }
}

resource "tfe_workspace_variable_set" "hcp" {
  for_each = local.hcp_workspaces_varset

  variable_set_id = each.value
  workspace_id    = tfe_workspace.workspace[each.key].id
}

# TODO: in future, get something in place to iterate over both sets of creds
resource "tfe_project_variable_set" "hcp_viewer" {
  variable_set_id = var.hcp_varsets["hcp:viewer"]

  for_each = toset([
    #    "Azure No-Code",
    "AWS No-Code",
    #    "Azure TF OSS to TFC",
    "AWS TF OSS to TFC",
  ])

  project_id = tfe_project.projects[each.key].id
}
