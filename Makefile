.PHONY: help init-static init-onoff static-plan static-apply onoff-plan onoff-apply on off fmt

TF_STATIC_DIR ?= infra/static
TF_ONOFF_DIR  ?= infra/onoff

help:
	@echo "Available targets:"
	@echo "  make init-static   # terraform init for static stack"
	@echo "  make static-plan   # terraform plan for static stack"
	@echo "  make init-onoff    # terraform init for toggle stack"
	@echo "  make onoff-plan    # terraform plan for toggle stack"
	@echo "  make on            # enable toggle stack (apply)"
	@echo "  make off           # disable toggle stack (destroy)"
	@echo "  make fmt           # terraform fmt across infra"

init-static:
	terraform -chdir=$(TF_STATIC_DIR) init

static-plan:
	terraform -chdir=$(TF_STATIC_DIR) plan

static-apply:
	terraform -chdir=$(TF_STATIC_DIR) apply

init-onoff:
	terraform -chdir=$(TF_ONOFF_DIR) init

onoff-plan:
	terraform -chdir=$(TF_ONOFF_DIR) plan -var-file=vars/base.tfvars -var-file=vars/toggles.tfvars

on:
	terraform -chdir=$(TF_ONOFF_DIR) apply -var-file=vars/base.tfvars -var-file=vars/toggles.tfvars

off:
	terraform -chdir=$(TF_ONOFF_DIR) destroy -var-file=vars/base.tfvars -var-file=vars/toggles.tfvars

fmt:
	terraform -chdir=$(TF_STATIC_DIR) fmt
	terraform -chdir=$(TF_ONOFF_DIR) fmt
