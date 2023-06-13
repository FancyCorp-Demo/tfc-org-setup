




variable "tfe_org" {
  type    = string
  default = "fancycorp"
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
