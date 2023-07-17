# Attach run task(s) to workspaces
# No Provider resource for this yet, so do via API
# https://www.terraform.io/cloud-docs/api-docs/run-tasks#attach-a-run-task-to-a-workspace

# Run task created by hand in advance
#
# Bridgecrew
# https://app.terraform.io/app/fancycorp/settings/tasks/task-L5VGW5tzomZDarsY
# https://www.bridgecrew.cloud/integrations
#
# Snyk
# https://app.terraform.io/app/fancycorp/settings/tasks/task-CiaJ9kBYzJWpJ2ir
# https://app.snyk.io/org/lucymhdavies/manage/integrations/terraform-cloud


# Run Tasks (configured manually)
variable "run_tasks" {
  type = map(string)
  default = {
    bridgecrew : "task-L5VGW5tzomZDarsY"
    snyk : "task-CiaJ9kBYzJWpJ2ir"
    infracost : "task-C2LTGML3fQeeCY6t"
    packer : "task-1wCvp5FNeaMiD6rt"
  }
}


locals {
  tasks = flatten(
    [
      for name, workspace in local.workspaces : [
        for task in workspace.tasks : [{
          # Unique ID for set
          id = "${name}/${task.task}"

          workspace_id = tfe_workspace.workspace[name].id,
          enforcement  = can(task.enforcement) ? task.enforcement : "advisory"
          task_id      = var.run_tasks[task.task]
        }]
      ]
      if can(workspace.tasks)
    ]
  )

  tasks_set = { for idx, p in local.tasks : p.id => p }
}

resource "tfe_workspace_run_task" "tasks" {
  for_each = local.tasks_set

  workspace_id      = each.value["workspace_id"]
  task_id           = each.value["task_id"]
  enforcement_level = each.value["enforcement"]
}






# TODO: Create HCP Packer Run Task w/ TF
# https://app.asana.com/0/0/1205072880312484/f
# https://registry.terraform.io/providers/hashicorp/hcp/latest/docs/guides/packer-run-tasks-with-terraform
