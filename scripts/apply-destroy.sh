#!/bin/bash
set -e

# Get AWS creds
source $(which doors) local sandbox

terraform apply -var="trigger_workspaces_destroy=true" -auto-approve
