tfe_org = "fancycorp"

ignored_workspaces = [
  # Vault subworkspaces, managed by the main workspace
  "ws-v8TqGweccZtot3My", # vault-config
  "ws-YKrFeWtW9HqZEfne", # vault-monitoring
  "ws-pZnas4ZbuLMNjwXs", # vault-config-aws
  "ws-3BE3eU1jQASHGXy6", # vault-config-bootstrap
  "ws-1j3ikuCy5a2FfjfN", # vault-config-pki
]

ignored_projects = [
  "prj-EJC7UT7zsvRgsuht", # Landing Zone
  "prj-nvBBsaBkThKbDRZ9", # Admin
]

default_ttl = "24h"
max_ttl     = "168h" # 7 days

log_level = "info"
dry_run   = false
