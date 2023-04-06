terraform {
  cloud {
    organization = "fancycorp"

    workspaces {
      name = "bootstrap"
    }
  }

  required_providers {
    tfe = {
      source = "hashicorp/tfe"
    }
  }
}

provider "tfe" {
  organization = "fancycorp"
}

resource "tfe_workspace" "lz" {
  name        = "tfc-landing-zone"
  description = "Create all the other workspaces, modules, config, etc. Everything else in the org."

  execution_mode = "local"
}




# TODO: AWS Creds
# TODO: Azure Creds
# TODO: Other Secrets


# TODO: Would also need to modify how the main thing gets its TFC creds for TerraCurl
