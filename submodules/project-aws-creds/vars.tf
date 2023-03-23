variable "oidc_provider_arn" {
  type        = string
  description = "The ARN for the app.terraform.io OIDC provider"
}

variable "oidc_provider_client_id_list" {
  type        = list(string)
  default     = ["aws.workload.identity"]
  description = "The audience value(s) to use in run identity tokens. Defaults to aws.workload.identity, but if your OIDC provider uses something different, set it here"
}

variable "tfc_organization_name" {
  type        = string
  description = "The name of your Terraform Cloud organization"
}

variable "tfc_project_name" {
  type        = string
  description = "The name of the project"
}
locals {
  tfc_project_nospaces = replace(var.tfc_project_name, " ", "")
}

variable "tfc_project_id" {
  type        = string
  description = "The id of the project"
}




# Temporary, while we need TerraCurl
variable "tfc_token" {
  type        = string
  description = "TFC Token for TerraCurl"
}
