#!/bin/bash
set -e

# Get AWS creds
source $(which doors) local sandbox

terraform apply -auto-approve

# Do this a second time, because for some reason no-code modules aren't immediately no-code enabled
terraform apply -auto-approve
