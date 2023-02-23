data "tfe_organization" "org" {
  name = var.tfe_org
}

resource "tfe_workspace" "workspace" {
  for_each = local.workspaces

  name = each.key

  description = lookup(
    each.value,
    "description",
    ""
  )

  organization = var.tfe_org
  tag_names = lookup(each.value,
    "tags",
  [])

  vcs_repo {
    identifier = lookup(
      each.value,
      "identifier",
      "FancyCorp-Demo/tfcb-setup"
    )
    oauth_token_id = var.vcs_oauth_github
    branch = lookup(
      each.value,
      "branch",
      "main"
    )
  }
  working_directory = lookup(
    each.value,
    "working_directory",
    ""
  )

  # Do not automatically trigger runs, as creds have not been uploaded yet
  queue_all_runs = false

  force_delete = lookup(
    each.value,
    "force_delete",
    false
  )


  auto_apply = lookup(
    each.value,
    "auto_apply",
    false
  )


  # get project ID based on name, if set, or default project if not
  project_id = try(
    tfe_project.projects[each.value.project].id,
    data.tfe_organization.org.default_project_id
  )

}


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


#
# Apply
#


# Now that creds have been pushed, we can trigger a run
resource "multispace_run" "trigger_workspaces" {
  # If we are triggering a run, there should be some multispace_run.trigger_workspaces workspaces
  for_each = var.trigger_workspaces ? local.workspace_names : local.null_workspace_names

  # TODO: See all of this? This is why we need a "create workspace" submodule
  depends_on = [
    tfe_workspace.workspace,
    tfe_variable.test,

    module.azure-creds,
    module.aws-creds,

    tfe_workspace_run_task.tasks,

    tfe_registry_module.public-modules,
    tfe_registry_module.private-modules,

    # Not strictly speaking needed... but in the real world it would be
    tfe_team_access.access,
    tfe_team.team,

    tfe_policy_set.all-workspaces,
    tfe_policy_set.test-workspaces,
    tfe_policy_set_parameter.org-test,
    tfe_policy_set.prod-workspaces,
    tfe_policy_set_parameter.org-prod,
  ]

  organization = var.tfe_org
  workspace    = each.key

  # Kick off an apply, but don't wait for it
  wait_for_apply = false
  # Do not destroy as part of this resource
  do_destroy = false


  # Do not retry after first failure
  # retry_attempts = 1
}

resource "multispace_run" "destroy_workspaces" {
  # If we are destroying, then there should be no multispace_run.destroy_workspaces workspaces
  #
  # This allows us to explicitly trigger a destroy by setting the trigger_workspaces_destroy variable
  # or to destroy everything with a simple terraform destroy
  for_each = var.trigger_workspaces_destroy ? local.null_workspace_names : local.workspace_names

  # TODO: See all of this? This is why we need a "create workspace" submodule
  depends_on = [
    tfe_workspace.workspace,
    tfe_variable.test,

    # Creds
    module.azure-creds,
    module.aws-creds,
    tfe_workspace_variable_set.hcp_viewer,
    tfe_variable.tfc-creds,

    tfe_workspace_run_task.tasks,

    tfe_registry_module.public-modules,
    tfe_registry_module.private-modules,

    # Not strictly speaking needed... but in the real world it would be
    tfe_team_access.access,
    tfe_team.team,

    tfe_policy_set.all-workspaces,
    tfe_policy_set.test-workspaces,
    tfe_policy_set_parameter.org-test,
    tfe_policy_set.prod-workspaces,
    tfe_policy_set_parameter.org-prod,
  ]

  organization = var.tfe_org
  workspace    = each.key

  # Do not actually kick off an Apply, but create the resource so we can Destroy later
  do_apply = false

  # Kick off the destroy, and wait for it to succeed
  # (this is default behaviour, but make it explicit)
  wait_for_destroy = true


  # Do not retry after first failure
  # retry_attempts = 1
}
