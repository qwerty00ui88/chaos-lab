.PHONY: help init-static init-onoff static-plan static-apply static-destroy onoff-plan onoff-apply onoff-destroy on off fmt update-kubeconfig

TF_STATIC_DIR ?= infra/static
TF_ONOFF_DIR  ?= infra/onoff
DEFAULT_EKS_REGION ?= ap-northeast-2

help:
	@echo "Available targets:"
	@echo "  make init-static    # terraform init for static stack"
	@echo "  make static-plan    # terraform plan for static stack"
	@echo "  make init-onoff     # terraform init for toggle stack"
	@echo "  make onoff-plan     # terraform plan for toggle stack"
	@echo "  make onoff-apply    # enable toggle stack (apply)"
	@echo "  make onoff-destroy  # disable toggle stack (destroy)"
	@echo "  make static-destroy # terraform destroy for static stack"
	@echo "  make fmt            # terraform fmt across infra"

init-static:
	terraform -chdir=$(TF_STATIC_DIR) init

static-plan:
	terraform -chdir=$(TF_STATIC_DIR) plan -var-file=vars/base.tfvars

static-apply:
	terraform -chdir=$(TF_STATIC_DIR) apply -var-file=vars/base.tfvars

static-destroy:
	terraform -chdir=$(TF_STATIC_DIR) destroy -var-file=vars/base.tfvars -auto-approve

init-onoff:
	terraform -chdir=$(TF_ONOFF_DIR) init

onoff-plan:
	@$(MAKE) update-kubeconfig
	terraform -chdir=$(TF_ONOFF_DIR) plan -var-file=vars/base.tfvars -var-file=vars/toggles.tfvars

onoff-apply:
	@$(MAKE) update-kubeconfig
	terraform -chdir=$(TF_ONOFF_DIR) apply -var-file=vars/base.tfvars -var-file=vars/toggles.tfvars
	@$(MAKE) update-kubeconfig

onoff-destroy:
	terraform -chdir=$(TF_ONOFF_DIR) destroy -var-file=vars/base.tfvars -var-file=vars/toggles.tfvars -auto-approve

fmt:
	terraform -chdir=$(TF_STATIC_DIR) fmt
	terraform -chdir=$(TF_ONOFF_DIR) fmt

update-kubeconfig:
	@./scripts/update_kubeconfig.sh $(TF_ONOFF_DIR) $(DEFAULT_EKS_REGION)
