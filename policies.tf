# Identify workspaces on which to apply policy sets
# TODO: in future, do something like:
# policy_sets:
# - production
# - test

locals {
  workspace_ids = [
    for v in tfe_workspace.workspace : v.id
  ]

  # Identify all Production workspaces
  prod_workspace_resources = {
    for k, v in tfe_workspace.workspace : k => v.id
    if lookup(local.workspaces[k], "production", false)
  }
  prod_workspace_ids = [
    for v in local.prod_workspace_resources : v
  ]

  # Identify all Test workspaces
  test_workspace_resources = {
    for k, v in tfe_workspace.workspace : k => v.id
    if lookup(local.workspaces[k], "test", false)
  }
  test_workspace_ids = [
    for v in local.test_workspace_resources : v
  ]

}
# TODO: Replace all of the above with project-mapped policy sets


#
# Sentinel Policies
#

resource "tfe_policy_set" "all-workspaces" {
  name         = "global"
  description  = "Standard Demo Policies"
  organization = var.tfe_org

  vcs_repo {
    identifier         = "hashi-strawb/tf-sentinel-policies"
    branch             = "main"
    ingress_submodules = false
    oauth_token_id     = var.vcs_oauth_github
  }

  global = true
  # If I'm using the org for other things at the same time...
  # workspace_ids = local.workspace_ids
}

resource "tfe_policy_set" "public-registry" {
  name         = "public-registry"
  description  = "Policies from the Public Registry"
  organization = var.tfe_org

  vcs_repo {
    identifier         = "FancyCorp-Demo/sentinel-policies"
    branch             = "main"
    ingress_submodules = false
    oauth_token_id     = var.vcs_oauth_github
  }
  policies_path = "public"

  global = true
  # If I'm using the org for other things at the same time...
  # workspace_ids = local.workspace_ids
}

resource "tfe_policy_set" "test-workspaces" {
  name         = "test-policies"
  description  = "Test Demo Policies: Soft Mandatory"
  organization = var.tfe_org

  vcs_repo {
    identifier         = "FancyCorp-Demo/sentinel-policies"
    branch             = "main"
    ingress_submodules = false
    oauth_token_id     = var.vcs_oauth_github
  }
  policies_path = "test"

  # defined below...
  workspace_ids = local.test_workspace_ids
}
resource "tfe_policy_set_parameter" "org-test" {
  key           = "organizations"
  value         = "[\"${var.tfe_org}\"]"
  policy_set_id = tfe_policy_set.test-workspaces.id
}

resource "tfe_policy_set" "prod-workspaces" {
  name         = "production-policies"
  description  = "Production Demo Policies: Hard Mandatory"
  organization = var.tfe_org

  vcs_repo {
    identifier         = "FancyCorp-Demo/sentinel-policies"
    branch             = "main"
    ingress_submodules = false
    oauth_token_id     = var.vcs_oauth_github
  }
  policies_path = "prod"

  # defined below...
  workspace_ids = local.prod_workspace_ids
}

resource "tfe_policy_set_parameter" "org-prod" {
  key           = "organizations"
  value         = "[\"${var.tfe_org}\"]"
  policy_set_id = tfe_policy_set.prod-workspaces.id
}
