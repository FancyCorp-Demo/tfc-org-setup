#!/bin/bash
set -e

# Get AWS creds
source $(which doors) local sandbox

terraform apply -var="trigger_workspaces=true" -auto-approve

echo
echo To apply:
echo   make apply-trigger
