variable "slack_webhook" {
  type = string

  # https://lmhd.slack.com/services/B03RGJTJG1K
  # add to secrets.auto.tfvars
}

resource "tfe_notification_configuration" "slack" {
  for_each = local.workspaces


  name             = "Health Checks"
  enabled          = true
  destination_type = "slack"
  triggers         = ["assessment:check_failure", "assessment:drifted", "assessment:failed", "run:errored", "run:needs_attention"]
  url              = var.slack_webhook
  workspace_id     = tfe_workspace.workspace[each.key].id
}
