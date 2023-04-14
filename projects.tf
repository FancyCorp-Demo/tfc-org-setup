#
# Create Project(s)
#

locals {
  # List of distinct projects in workspaces
  workspace_projects = toset(
    distinct(
      flatten(
        [
          for workspace in local.workspaces : [
            workspace.project
          ] if can(workspace.project)
        ]
      )
    )
  )

  other_projects = [
    "AWS No-Code",
    "Azure No-Code",

    "Azure TF OSS to TFC",
  ]

  projects = setunion(
    local.workspace_projects,
    local.other_projects,
  )

}

resource "tfe_project" "projects" {
  for_each = local.projects



  organization = var.tfe_org

  name = each.value



  # This forces any workspaces in this project to be updated before the project
  # is destroyed
  #
  # e.g. if moving a workspace out of a project would leave the project empty,
  # and thus we delete the project... move the workspace first
  lifecycle {
    create_before_destroy = true
  }
}
