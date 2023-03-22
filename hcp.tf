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


# TODO: Map VarSet to Projects with the TFE provider once that's possible

resource "terracurl_request" "hcp_viewer" {
  name = "hcp_viewer"
  url  = "https://app.terraform.io/api/v2/varsets/${var.hcp_viewer_varset}/relationships/projects"

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
    },
    {
      "type": "projects",
      "id": "${tfe_project.projects["AWS No-Code"].id}"
    }
  ]
}
EOF
}
