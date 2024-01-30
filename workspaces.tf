
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


  # TODO: we also need a "do not trigger a delete" flag separate from this
  # i.e. for workspaces we don't want to force delete, but we also don't want
  # to trigger destroy runs on
  # (i.e. those which will be destroyed by a workspace runner)
  #
  # practically... we probably don't need this yet, because all tfe_workspace_run resources
  # are lumped in together, so we don't actually delete any workspaces until after
  # all workspaces have been destroyed
  #
  # but if/when we get around to refactoring this... at that point it will be useful
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

  # Depends on: https://github.com/hashicorp/terraform-provider-tfe/pull/1123
  # TODO: Make this conditional (e.g. on this being a downstream workspace)
  #auto_apply_run_trigger = lookup(
  #  each.value,
  #  "auto_apply",
  #  false
  #)


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

  terraform_version = lookup(
    each.value,
    "terraform_version",
    "latest"
  )


  # Default behaviour, trigger plans only when files change in working directory
  file_triggers_enabled = lookup(
    each.value,
    "file_triggers_enabled",
    true
  )
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


resource "tfe_workspace_run" "trigger_workspaces" {
  for_each = var.trigger_workspaces ? local.workspace_names_sometimes_trigger : local.workspace_names_always_trigger

  # TODO: See all of this? This is why we need a "create workspace" submodule
  depends_on = [
    tfe_workspace.workspace,
    tfe_variable.test,

    #module.azure-creds,
    module.aws-creds,

    tfe_workspace_run_task.tasks,

    # Any dependencies between workspaces
    tfe_run_trigger.run_trigger,

    # Modules
    tfe_registry_module.public-modules,
    tfe_registry_module.private-modules,

    # Not strictly speaking needed... but in the real world it would be
    tfe_team_access.access,
    tfe_team.team,

    # We definitiely need policies in place before we do any applies
    # (we don't really need them before destroy)
    tfe_policy_set.all-workspaces,
    tfe_policy_set.public-registry,
    tfe_policy_set.test-workspaces,
    tfe_policy_set_parameter.org-test,
    tfe_policy_set.prod-workspaces,
    tfe_policy_set_parameter.org-prod,
  ]

  workspace_id = tfe_workspace.workspace[each.key].id

  # Kick off an apply, but don't wait for it
  apply {
    # use workspace default setting for apply method
    manual_confirm = !tfe_workspace.workspace[each.key].auto_apply

    retry = false # Only try once

    wait_for_run = false # Fire and forget
  }
}

resource "tfe_workspace_run" "destroy_workspaces" {
  # trigger destruction on workspaces that aren't marked as Force Delete
  for_each = local.workspace_names_trigger_destroy

  # TODO: See all of this? This is why we need a "create workspace" submodule
  depends_on = [
    tfe_workspace.workspace,
    tfe_variable.test,

    # Creds
    #module.azure-creds,
    module.aws-creds,
    tfe_workspace_variable_set.hcp,
    tfe_workspace_variable_set.tfc-creds,
    tfe_variable.tfc-creds,

    # Any dependencies between workspaces
    tfe_run_trigger.run_trigger,

    # Modules
    tfe_registry_module.public-modules,
    tfe_registry_module.private-modules,

    # We definitiely need policies in place before we do any applies
    # we don't really need them before destroy, but leave them here or Policy Evaluation hangs on destroy
    tfe_policy_set.all-workspaces,
    tfe_policy_set.public-registry,
    tfe_policy_set.test-workspaces,
    tfe_policy_set_parameter.org-test,
    tfe_policy_set.prod-workspaces,
    tfe_policy_set_parameter.org-prod,
  ]

  # ideally, we would depend on an Upstream workspace if one exists
  # (we can't, without introducing circular dependencies)
  workspace_id = tfe_workspace.workspace[each.key].id

  # Do not actually kick off an Apply, but create the resource so we can Destroy later
  # (i.e. we're omitting the apply{} block)

  # Kick off the destroy, and wait for it to succeed
  # (this is default behaviour, but make it explicit)
  destroy {
    manual_confirm = false # Let TF confirm this itself

    retry = false # Only try once

    wait_for_run = true # Wait until destroy has finished before removing this resource
  }
}
