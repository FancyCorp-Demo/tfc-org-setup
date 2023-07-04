
variable "slack_webhook_secret" {
  type = string

  # https://api.slack.com/apps/A059FURH5PG/incoming-webhooks?success=1
  default = "FancyCorp-TFC-Org-Bootstrapping"
}

data "hcp_vault_secrets_app" "slack_webhook" {
  app_name = var.slack_webhook_secret
}

resource "tfe_notification_configuration" "slack" {
  for_each = local.workspaces


  name             = "Health Checks"
  enabled          = true
  destination_type = "slack"
  triggers         = ["assessment:check_failure", "assessment:drifted", "assessment:failed", "run:errored", "run:needs_attention"]
  url              = data.hcp_vault_secrets_app.slack_webhook.secrets["slack_webhook"]
  workspace_id     = tfe_workspace.workspace[each.key].id
}
