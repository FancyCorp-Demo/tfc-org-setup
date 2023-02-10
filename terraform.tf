#
# Keep our state in TFC
#
terraform {
  backend "remote" {
    organization = "hashi_strawb_testing"

    workspaces {
      name = "demo-tfcb-fancycorp"
    }
  }

  required_providers {
    tfe = {
      source  = "hashicorp/tfe"
      version = ">= 0.41.0, < 1.0.0"
    }
    doormat = {
      source = "doormat.hashicorp.services/hashicorp-security/doormat"
    }
    terracurl = {
      source = "devops-rob/terracurl"
      #      version = "0.1.0"
    }


    multispace = {
      source  = "lucymhdavies/multispace"
      version = "0.2.0"

      #    # ~/.terraform.d/plugins/terraform.local/local/multispace/0.2.0/darwin_amd64
      #      source  = "terraform.local/local/multispace"
      #      version = "~> 0.2.0"
    }
  }

}

provider "tfe" {
}
