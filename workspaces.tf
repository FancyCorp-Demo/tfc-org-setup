
# terraform apply -var="trigger_workspaces=true"
variable "trigger_workspaces" {
  type    = bool
  default = false
}
# terraform apply -var="trigger_workspaces_destroy=true"
variable "trigger_workspaces_destroy" {
  type    = bool
  default = false
}

# WIP: Dynamic TF Config
locals {
  # Find all YAML files in the workspaces dir
  workspace_files = setsubtract(
    fileset("${path.module}", "workspaces/**/*{yml,yaml}"),
    ["workspaces/example.yml"]
  )

  # Parse them all
  workspace_files_decoded = {
    for filename in local.workspace_files :
    trimsuffix(basename(filename), ".yml") =>
    merge(
      {
        # Default values when not specified in the YAML files
        creds       = [],
        permissions = [],

        filename        = filename,
        file_github_url = "https://github.com/FancyCorp-Demo/tfc-org-setup/blob/main/${filename}"
      },
      yamldecode(file(filename)),
    )
  }

  workspaces      = local.workspace_files_decoded
  null_workspaces = tomap({})


  workspace_names = toset([
    for k, v in local.workspaces : k
  ])

  workspace_names_sometimes_trigger = toset([
    for k, v in local.workspaces : k
    if !can(v.upstream_workspaces)
  ])

  workspace_names_always_trigger = toset([
    for k, v in local.workspaces : k
    if lookup(v, "auto_trigger", false)
  ])

  workspace_names_trigger_destroy = toset([
    for k, v in local.workspaces : k
    if !lookup(v, "force_delete", false)
  ])
}




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


  # Allow all other workspaces to access this workspace's outputs
  # TODO: see if we can do something with remote_state_consumer_ids in future
  global_remote_state = lookup(
    each.value,
    "global_remote_state",
    false
  )


  assessments_enabled = lookup(
    each.value,
    "assessments_enabled",
    false
  )


  source_name = "TFE Provider"
  source_url  = each.value.file_github_url

  lifecycle {
    ignore_changes = [
      source_name,
      source_url,
    ]
  }

  terraform_version = "latest"
}


#
# Run Triggers
#

locals {
  # Find any workspaces which declare any upstream workspaces
  # returns a map from downstream:[upstreams]
  workspaces_with_upstreams = {
    for k, v in local.workspaces : k => v.upstream_workspaces
    if can(v.upstream_workspaces)
  }

  # Now convert this into an list of unique downstream/upstream pairs
  workspaces_upstream_to_downstream = flatten([
    for downstream, upstreams in local.workspaces_with_upstreams : [
      for upstream in upstreams :
      {
        downstream : downstream,
        upstream : upstream,
      }
    ]
  ])

  # Finally... we need a key for this, so we can for_each over it
  workspaces_upstream_to_downstream_map = {
    for index, ud in local.workspaces_upstream_to_downstream :
    "up:${ud.upstream};down:${ud.downstream}" => ud
  }
}

resource "tfe_run_trigger" "run_trigger" {
  for_each      = local.workspaces_upstream_to_downstream_map
  workspace_id  = tfe_workspace.workspace[each.value.downstream].id
  sourceable_id = tfe_workspace.workspace[each.value.upstream].id
}




#
# Apply
#


# Now that creds have been pushed, we can trigger a run
resource "multispace_run" "trigger_workspaces" {
  # If we are triggering a run, there should be some multispace_run.trigger_workspaces workspaces
  for_each = var.trigger_workspaces ? local.workspace_names_sometimes_trigger : local.workspace_names_always_trigger

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
  # trigger destruction on workspaces that aren't marked as Force Delete
  for_each = local.workspace_names_trigger_destroy

  # TODO: See all of this? This is why we need a "create workspace" submodule
  depends_on = [
    tfe_workspace.workspace,
    tfe_variable.test,

    # Creds
    module.azure-creds,
    module.aws-creds,
    tfe_workspace_variable_set.hcp,
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
    tfe_policy_set.public-registry,
  ]

  # TODO: if we can, depend on an Upstream workspace if one exists

  organization = var.tfe_org
  workspace    = each.key

  # Do not actually kick off an Apply, but create the resource so we can Destroy later
  do_apply = false

  # Kick off the destroy, and wait for it to succeed
  # (this is default behaviour, but make it explicit)
  wait_for_destroy = true


  # Do not retry after first failure
  # retry_attempts = 1


  timeouts {
    # To account for the amount of time it takes to destroy an HCP Vault cluster...
    delete = "60m"
  }
}
