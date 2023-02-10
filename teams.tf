
#
# Teams
#

locals {
  # List of distinct teams
  teams = toset(
    distinct(
      flatten(
        [
          for workspace in local.workspaces : [
            for team, access in workspace.permissions : [
              team,
            ]
          ]
        ]
      )
    )
  )

  # List of {workspace, team, access}
  permissions = flatten(
    [
      for name, workspace in local.workspaces : [
        for team, access in workspace.permissions : [{
          # Unique ID for set
          id = "${name}/${team}"

          workspace_id = tfe_workspace.workspace[name].id,
          team         = tfe_team.team[team].id,
          access       = access,
        }]
      ]
    ]
  )

  permissions_set = { for idx, p in local.permissions : p.id => p }
}

resource "tfe_team" "team" {
  for_each = local.teams

  name         = each.key
  organization = var.tfe_org
}

resource "tfe_team_access" "access" {
  for_each = local.permissions_set


  workspace_id = each.value.workspace_id
  team_id      = each.value.team
  access       = each.value.access
}
