#!/bin/bash
set -e

# TODO: check if currently specified GCP project still exists
# If not... do the below
# And if that fails... prompt to create with doormat

echo -n "gcp_project_id = " \
	| tee gcp-project.auto.tfvars
gcloud projects list --format=json --filter "name=strawb-demos-test" \
	| jq ".[].projectId" \
	| tee -a gcp-project.auto.tfvars

