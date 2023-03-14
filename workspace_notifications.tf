
// Enabled just for Health Checks... but provider doesn't support that yet
// https://github.com/hashicorp/terraform-provider-tfe/issues/652

/*
resource "tfe_notification_configuration" "slack" {
  for_each = local.workspaces


  name             = "Health Checks"
  enabled          = true
  destination_type = "slack"
  triggers         = ["assessment:check_failure", "assessment:drifted", "assessment:failed"]
  url              = var.slack_webhook
  workspace_id     = tfe_workspace.workspace[each.key].id
}
*/

# TODO: the provider DOES support this now!
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
      "url": "${var.slack_webhook}",
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
