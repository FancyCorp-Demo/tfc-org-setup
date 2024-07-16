#
# Keep our state in TFC
#
terraform {
  backend "remote" {
    organization = "fancycorp"

    workspaces {
      name = "tfc-landing-zone"
    }
  }

  required_providers {
    tfe = {
      source  = "hashicorp/tfe"
      version = ">= 0.57.0, < 1.0.0"

      # ~/.terraform.d/plugins/terraform.local/local/tfe/x.y.z/darwin_amd64
      #source = "terraform.local/local/tfe"
    }
    hcp = {
      source  = "hashicorp/hcp"
      version = ">= 0.61.0"
    }
    doormat = {
      source = "doormat.hashicorp.services/hashicorp-security/doormat"
    }
    terracurl = {
      source = "devops-rob/terracurl"
      #      version = "0.1.0"
    }
  }

}

provider "tfe" {
  organization = "fancycorp"
}

provider "hcp" {
  project_id = "d6c96d2b-616b-4cb8-b78c-9e17a78c2167"
}
