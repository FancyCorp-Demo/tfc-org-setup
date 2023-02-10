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


variable "slack_webhook" {
  type = string
}



variable "tfe_org" {
  type    = string
  default = "fancycorp"
}




# WIP: Dynamic TF Config
locals {
  # Find all YAML files in the workspaces dir
  workspace_files = setsubtract(
    fileset(path.module, "workspaces/*.yml"),
    ["workspaces/example.yml"]
  )

  # Parse them all
  workspace_files_decoded = {
    for filename in local.workspace_files :
    trimsuffix(basename(filename), ".yml") =>
    merge(
      {
        # Default values when not specified in the YAML files
        creds       = "",
        permissions = [],
      },
      yamldecode(file(filename)),
    )
  }

  workspaces      = local.workspace_files_decoded
  null_workspaces = tomap({})


  workspace_names = toset([
    for k, v in local.workspaces : k
  ])
  null_workspace_names = toset([])
}



# Create one by hand per instructions in https://www.terraform.io/docs/cloud/vcs/github.html
# Easier than trying to get TF to talk to GitHub etc.
# https://github.com/settings/applications/1722465
# https://app.terraform.io/app/fancycorp/settings/version-control
#
# OAuth Token ID from https://app.terraform.io/app/fancycorp/settings/version-control
variable "vcs_oauth_github" {
  type    = string
  default = "ot-8hSCfUe8VncQMmW6"
}



# For use in curl commands, to handle things the TFE provider does not yet support
variable "tfc_credentials_file" {
  type    = string
  default = "~/.terraform.d/credentials.tfrc.json"
}
locals {
  # TODO: this needs some more checks on it to make sure it's okay
  # and then maybe worth converting to a module
  tfc_credentials_file_content = fileexists(var.tfc_credentials_file) ? file(var.tfc_credentials_file) : ""
  tfc_credentials_file_json    = jsondecode(local.tfc_credentials_file_content)
  tfc_token                    = local.tfc_credentials_file_json["credentials"]["app.terraform.io"]["token"]
}
