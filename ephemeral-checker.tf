# Creds needed for https://github.com/hashi-strawb/tfc-ephemeral-workspace-check

resource "tfe_team" "ephemeral-workspace-checker" {
  name = "ephemeral-workspace-checker"
  organization_access {
    manage_workspaces = true
    manage_projects   = true
  }
}

resource "tfe_team_token" "ephemeral-workspace-checker" {
  team_id = tfe_team.ephemeral-workspace-checker.id
}

output "ephemeral_workspace_checker_tfe_token" {
  value     = tfe_team_token.ephemeral-workspace-checker.token
  sensitive = true
}
