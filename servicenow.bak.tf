

output "service-now-instructions" {
  value = nonsensitive(<<EOT

Ensure your ServiceNow Dev instance has access to the Terraform app.
Ask in #proj-tf-servicenow on Slack

To setup, follow instructions from here:
https://www.terraform.io/cloud-docs/integrations/service-now
* Install the ServiceNow Integration
* Connect ServiceNow to Terraform Cloud
	* Variables needed are below

In ServiceNow: Terraform > Configs
	Org:   ${var.tfe_org}
	Token: ${tfe_team_token.manage-workspaces.token}


Also increase the poll frequency.
In ServiceNow: Workflow - Scheduled Workflows
	Worker Poll Run State
	Edit
	Set Repeat Interval to 5 seconds


For Catalog items, follow:
https://www.terraform.io/cloud-docs/integrations/service-now/service-catalog
* In ServiceNow: Service Catalog > Catalogs

To add a specific VCS repo
* In ServiceNow: Terraform > VCS Repositories
	* Name: Hello World
	* Identifier: hashi-strawb/terraform-hello-world
	* GitHub OAuth Token ID: ${var.vcs_oauth_github}
EOT
  )
}
