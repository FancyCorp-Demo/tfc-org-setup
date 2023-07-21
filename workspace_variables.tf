
# List of {workspace and variables}
locals {
  vars = flatten(
    [
      for name, workspace in local.workspaces : [
        for var in workspace.vars : [{
          # Unique ID for set
          id = "${name}/${var.key}"


          # TODO: rewrite this overcomplicated batshit with this:
          # https://developer.hashicorp.com/terraform/language/expressions/type-constraints#optional-object-type-attributes
          # that'll be much easier to understand
          workspace_id = tfe_workspace.workspace[name].id
          key          = var.key
          value        = var.value
          hcl          = can(var.hcl) ? var.hcl : false
          category     = can(var.category) ? var.category : "terraform"
          description  = can(var.description) ? var.description : ""
          sensitive    = can(var.sensitive) ? var.sensitive : false
        }]
      ]
      if can(workspace.vars)
    ]
  )

  /* Example
vars = [
  {
    "category" = "terraform"
    "description" = ""
    "key" = "key_1"
    "sensitive" = false
    "value" = "value 1"
    "workspace_id" = "ws-diYep9n8fjyQvgzV"
  },
  {
    "category" = "env"
    "description" = "flibbles"
    "key" = "KEY_B"
    "sensitive" = false
    "value" = "hello world"
    "workspace_id" = "ws-diYep9n8fjyQvgzV"
  },
]
*/

  vars_set = { for idx, p in local.vars : p.id => p }

  /* Example
vars_set = {
  "ws-diYep9n8fjyQvgzV/KEY_B" = {
    "category" = "env"
    "description" = "flibbles"
    "key" = "KEY_B"
    "sensitive" = false
    "value" = "hello world"
    "workspace_id" = "ws-diYep9n8fjyQvgzV"
  }
  "ws-diYep9n8fjyQvgzV/key_1" = {
    "category" = "terraform"
    "description" = ""
    "key" = "key_1"
    "sensitive" = false
    "value" = "value 1"
    "workspace_id" = "ws-diYep9n8fjyQvgzV"
  }
}
*/
}

resource "tfe_variable" "test" {
  for_each = local.vars_set

  workspace_id = each.value.workspace_id
  key          = each.value.key
  value        = each.value.value
  hcl          = each.value.hcl
  category     = each.value.category
  description  = each.value.description
  sensitive    = each.value.sensitive
}
