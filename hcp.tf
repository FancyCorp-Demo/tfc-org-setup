
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


# TODO: Map VarSet to Projects with the TFE provider once that's possible

resource "terracurl_request" "hcp_viewer_nocode" {
  name = "hcp_viewer"
  url  = "https://app.terraform.io/api/v2/varsets/${var.hcp_varsets["hcp:viewer"]}/relationships/projects"

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
    },
    {
      "type": "projects",
      "id": "${tfe_project.projects["Azure TF OSS to TFC"].id}"
    }
  ]
}
EOF
}

