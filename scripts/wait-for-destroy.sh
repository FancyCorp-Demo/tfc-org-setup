#!/bin/bash
set -e

# This script currently does nothing useful, but some of the TODOs below will be useful
exit 0



# TODO: can we get TF to run this?

export TOKEN=$(cat ~/.terraform.d/credentials.tfrc.json | jq -r '.credentials."app.terraform.io".token')


have_initiated_destroy=false


# TODO: check for workspaces which are currently "applying"
# wait for these runs to finish



workspaces=$(
curl -s \
	--header "Authorization: Bearer $TOKEN" \
	--header "Content-Type: application/vnd.api+json" \
	https://app.terraform.io/api/v2/organizations/fancycorp/workspaces \
	| jq .
)


# TODO: Check for any of these which are not doing anything, and currently locked. Unlock them.

#zero_resource_workspaces=$(echo ${workspaces} | jq -r '.data[] | select(.attributes["resource-count"] == 0) | .attributes["name"]')
