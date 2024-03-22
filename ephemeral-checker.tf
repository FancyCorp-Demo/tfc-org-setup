# Creds needed for https://github.com/hashi-strawb/tfc-ephemeral-workspace-check

resource "tfe_team" "ephemeral-workspace-checker" {
  name = "ephemeral-workspace-checker"
  organization_access {
    manage_workspaces = true
    manage_projects   = true
  }
}

resource "time_rotating" "rotate" {
  rotation_days = 7
}
# workaround from https://github.com/hashicorp/terraform-provider-time/issues/118#issuecomment-1316056478
resource "time_static" "rotate" {
  rfc3339 = time_rotating.rotate.rfc3339
}

resource "tfe_team_token" "ephemeral-workspace-checker" {
  team_id = tfe_team.ephemeral-workspace-checker.id

  lifecycle {
    replace_triggered_by = [
      time_static.rotate
    ]
  }
}


#
# HVS App + Secret
#

resource "hcp_vault_secrets_app" "app" {
  app_name    = "tfc-ephemeral-workspace-checker"
  description = "TFC API token for ${tfe_team.ephemeral-workspace-checker.name} in hashi_strawb_testing"
}

resource "hcp_vault_secrets_secret" "secret" {
  app_name     = hcp_vault_secrets_app.app.app_name
  secret_name  = "TFE_TOKEN"
  secret_value = tfe_team_token.ephemeral-workspace-checker.token
}
