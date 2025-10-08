
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
    #    {
    #      namespace       = "Azure",
    #      module_provider = "azurerm",
    #      name            = "vnet",
    #    },
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
    #    "FancyCorp-Demo/terraform-azure-webserver",
    "hashi-strawb/terraform-aws-account-numbers",
  ]
}


resource "tfe_registry_module" "private-modules" {
  for_each = toset(local.private_modules)

  vcs_repo {
    display_identifier = each.key
    identifier         = each.key
    oauth_token_id     = var.vcs_oauth_github
    tags               = true
  }
}




# Currently broken...
# ╷
#│ Error: Missing required argument
#│
#│   with tfe_no_code_module.private-nocode-modules,
#│   on registry.tf line 94, in resource "tfe_no_code_module" "private-nocode-modules":
#│   94: resource "tfe_no_code_module" "private-nocode-modules" {
#│
#│ "variable_options": all of `variable_options,version_pin` must be specified
#╵

/*
locals {
  # TODO: definitely want to start looking into pulling these from YAML files
  private_nocode_modules = {

    "FancyCorp-Demo/terraform-aws-webserver-nocode" : {
      variable_options = [
        {
          name    = "packer_bucket_name",
          type    = "string",
          options = ["webserver"],
        },
        {
          name    = "packer_channel",
          type    = "string",
          options = ["production", "latest"],
        },
        {
          name    = "instance_type",
          type    = "string",
          options = ["t3.micro"],
        },
        {
          name    = "aws-region",
          type    = "string",
          options = ["eu-west-1", "eu-west-2"],
        }
      ]
    },
    "FancyCorp-Demo/terraform-aws-nocode-s3-static-website" : {
      variable_options = [
        {
          name    = "region",
          type    = "string",
          options = ["eu-west-1", "eu-west-2"],
        },
      ],
    },

  }
}

resource "tfe_registry_module" "private-nocode-modules" {
  for_each = local.private_nocode_modules

  vcs_repo {
    display_identifier = each.key
    identifier         = each.key
    oauth_token_id     = var.vcs_oauth_github
    tags               = true
  }
}


resource "tfe_no_code_module" "private-nocode-modules" {
  for_each = local.private_nocode_modules

  registry_module = tfe_registry_module.private-nocode-modules[each.key].id

  dynamic "variable_options" {
    for_each = lookup(each.value, "variable_options", [])

    content {
      name    = variable_options.value["name"]
      type    = variable_options.value["type"]
      options = variable_options.value["options"]
    }
  }

  # TODO: handle variable_options too... though I've not figured out how I want to do that yet
  # short term, fill in the map values in private_nocode_modules
  # medium term, start parsing yaml files for this
  # long term... see if we can get some file from the repo itself
}
*/
