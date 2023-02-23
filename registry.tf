
#
# Registry
#

# TODO: pull these from config files?

variable "public_modules" {
  type = list(object({
    namespace       = string,
    module_provider = string,
    name            = string,
  }))

  default = [
    {
      namespace       = "terraform-aws-modules",
      module_provider = "aws",
      name            = "vpc",
    },
    {
      namespace       = "Azure",
      module_provider = "azurerm",
      name            = "vnet",
    },
  ]
}
locals {
  public_modules = {
    for index, module in var.public_modules :
    index => module
  }
}

resource "tfe_registry_module" "public-modules" {
  for_each = local.public_modules

  organization    = var.tfe_org
  namespace       = each.value.namespace
  module_provider = each.value.module_provider
  name            = each.value.name
  registry_name   = "public"
}

locals {
  private_modules = [
    "FancyCorp-Demo/terraform-aws-webserver",
    "hashi-strawb/terraform-azure-webserver",
    "hashi-strawb/terraform-aws-account-numbers",
  ]
}


resource "tfe_registry_module" "private-modules" {
  for_each = toset(local.private_modules)

  vcs_repo {
    display_identifier = each.key
    identifier         = each.key
    oauth_token_id     = var.vcs_oauth_github
  }
}


locals {
  private_nocode_modules = [
    "FancyCorp-Demo/terraform-aws-webserver-nocode",
  ]
}

resource "tfe_registry_module" "private-nocode-modules" {
  for_each = toset(local.private_nocode_modules)

  vcs_repo {
    display_identifier = each.key
    identifier         = each.key
    oauth_token_id     = var.vcs_oauth_github
  }

  no_code = true
}
