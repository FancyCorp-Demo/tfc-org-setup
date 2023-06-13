
variable "slack_webhook_secret" {
  type = string

  # https://api.slack.com/apps/A059FURH5PG/incoming-webhooks?success=1
  default = "FancyCorp-TFC-Org-Bootstrapping"
}

data "hcp_vault_secrets_app" "slack_webhook" {
  app_name = var.slack_webhook_secret
}

# TODO: pending https://github.com/hashicorp/terraform-provider-tfe/issues/926
#               https://github.com/hashicorp/terraform-provider-tfe/pull/927
/*
resource "tfe_notification_configuration" "slack" {
  for_each = local.workspaces


  name             = "Health Checks"
  enabled          = true
  destination_type = "slack"
  triggers         = ["assessment:check_failure", "assessment:drifted", "assessment:failed"]
  url              = data.hcp_vault_secrets_app.slack_webhook.secrets["slack_webhook"]
  workspace_id     = tfe_workspace.workspace[each.key].id
}
*/

resource "terracurl_request" "health_check_notifications" {
  for_each = local.workspaces

  name   = "health_check"
  url    = "https://app.terraform.io/api/v2/workspaces/${tfe_workspace.workspace[each.key].id}/notification-configurations"
  method = "POST"

  headers = {
    Authorization = "Bearer ${local.tfc_token}"
    Content-Type  = "application/vnd.api+json"
  }
  response_codes = [201]

  request_body = <<EOF
{
  "data": {
    "type": "notification-configuration",
    "attributes": {
      "destination-type": "slack",
      "enabled": true,
      "name": "Health Checks",
      "url": "${data.hcp_vault_secrets_app.slack_webhook.secrets["slack_webhook"]}",
      "triggers": [
        "assessment:check_failure",
        "assessment:drifted",
        "assessment:failed"
      ]
    }
  }
}
EOF

}
