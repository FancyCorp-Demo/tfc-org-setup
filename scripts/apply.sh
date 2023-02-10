#!/bin/bash
set -e

# Get AWS creds
source $(which doors) local sandbox

terraform apply -auto-approve
