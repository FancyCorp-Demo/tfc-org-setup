#!/bin/bash
set -e

# Get AWS creds
source $(which doors) local sandbox

#terraform destroy
terraform apply -destroy -auto-approve
# TODO: Remove SSO Users
