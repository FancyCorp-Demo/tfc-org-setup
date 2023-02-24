#
# Based on https://github.com/hashicorp/terraform-dynamic-credentials-setup-examples/blob/main/azure/tfc-workspace.tf
#



# The following variables must be set to allow runs
# to authenticate to Azure.
resource "tfe_variable" "enable_azure_provider_auth" {
  workspace_id = var.tfc_workspace_id

  key      = "TFC_AZURE_PROVIDER_AUTH"
  value    = "true"
  category = "env"

  description = "Enable the Workload Identity integration for Azure."
}

resource "tfe_variable" "tfc_azure_client_id" {
  workspace_id = var.tfc_workspace_id

  key      = "TFC_AZURE_RUN_CLIENT_ID"
  value    = azuread_application.tfc_application.application_id
  category = "env"

  description = "The Azure Client ID runs will use to authenticate."
}

resource "tfe_variable" "tfc_azure_audience" {
  workspace_id = var.tfc_workspace_id

  key      = "TFC_AZURE_WORKLOAD_IDENTITY_AUDIENCE"
  value    = var.tfc_azure_audience
  category = "env"

  description = "The value to use as the audience claim in run identity tokens"
}



# And this stuff is for the AzureAD TF Provider, so it knows the rest of the
# information it needs for Azure auth

resource "tfe_variable" "tfc_arm_subscription_id" {
  workspace_id = var.tfc_workspace_id

  key      = "ARM_SUBSCRIPTION_ID"
  value    = data.azurerm_subscription.current.subscription_id
  category = "env"

  description = "The Azure Subscription to use"
}

resource "tfe_variable" "tfc_arm_tenant_id" {
  workspace_id = var.tfc_workspace_id

  key      = "ARM_TENANT_ID"
  value    = azuread_service_principal.tfc_service_principal.application_tenant_id
  category = "env"

  description = "The AzureAD Tenant to use"
}
