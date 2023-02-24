#
# Based on https://github.com/hashicorp/terraform-dynamic-credentials-setup-examples/blob/main/azure/azure.tf
#


# Creates an application registration within Azure Active Directory, specific to the Workspace

data "azuread_client_config" "current" {}
resource "azuread_application" "tfc_application" {
  display_name = "tfc-${var.tfc_organization_name}-${var.tfc_workspace_name}"
  owners       = [data.azuread_client_config.current.object_id]
}


# Creates a service principal associated with the previously created
# application registration.
resource "azuread_service_principal" "tfc_service_principal" {
  application_id = azuread_application.tfc_application.application_id
}

# Creates a role assignment which controls the permissions the service
# principal has within the Azure subscription.
data "azurerm_subscription" "current" {}
resource "azurerm_role_assignment" "tfc_role_assignment" {
  scope                = data.azurerm_subscription.current.id
  principal_id         = azuread_service_principal.tfc_service_principal.object_id
  role_definition_name = "Contributor"
}


# Creates federated identity credentials which ensures that the given
# workspace will be able to authenticate to Azure for the "plan" and "apply" run phases
resource "azuread_application_federated_identity_credential" "tfc_federated_credential_plan" {
  application_object_id = azuread_application.tfc_application.object_id
  display_name          = "tfc-plan"
  audiences             = [var.tfc_azure_audience]
  issuer                = "https://${var.tfc_hostname}"
  subject = join(
    ":", [
      "organization:${var.tfc_organization_name}",
      "project:${var.tfc_workspace_project}",
      "workspace:${var.tfc_workspace_name}",
      "run_phase:plan"
    ]
  )
}
resource "azuread_application_federated_identity_credential" "tfc_federated_credential_apply" {
  application_object_id = azuread_application.tfc_application.object_id
  display_name          = "tfc-apply"
  audiences             = [var.tfc_azure_audience]
  issuer                = "https://${var.tfc_hostname}"
  subject = join(
    ":", [
      "organization:${var.tfc_organization_name}",
      "project:${var.tfc_workspace_project}",
      "workspace:${var.tfc_workspace_name}",
      "run_phase:apply"
    ]
  )
}
