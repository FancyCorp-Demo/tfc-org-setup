.PHONY: gcp-project apply apply-trigger apply-destroy destroy init wait-for-destroy

default: apply

gcp-project:
	@echo "========================================"
	@echo "Getting GCP Project ID"
	@echo "========================================"
	./scripts/gcp-project.sh

init:
	@echo "========================================"
	@echo "Terraform Init"
	@echo "========================================"
	terraform init -upgrade

apply: init
	@echo "========================================"
	@echo "Applying (TFC resources only)"
	@echo "========================================"
	./scripts/apply.sh

apply-trigger: init
	@echo "========================================"
	@echo "Applying (With Workspace Applies)"
	@echo "========================================"
	./scripts/apply-trigger.sh

apply-destroy:
	@echo "========================================"
	@echo "Applying (With Workspace Destroys)"
	@echo "========================================"
	./scripts/apply-destroy.sh

wait-for-destroy:
	@echo "========================================"
	@echo "Waiting for Workspace Destroys"
	@echo "========================================"
	./scripts/wait-for-destroy.sh

destroy: wait-for-destroy
	@echo "========================================"
	@echo "Destroying TFC Resources"
	@echo "========================================"
	./scripts/destroy.sh

open:
	open https://app.terraform.io/app/fancycorp/workspaces
