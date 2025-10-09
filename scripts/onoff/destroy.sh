#!/bin/bash
set -euo pipefail

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:${PATH:-}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
TF_DIR="${REPO_ROOT}/infra/onoff"
STATIC_TF_DIR="${REPO_ROOT}/infra/static"
TF_CMD=${TF_CMD:-terraform}

VAR_FILES=("vars/base.tfvars" "vars/toggles.tfvars")
DESIRED_NAMESPACE="${INGRESS_NAMESPACE:-target-app}"
DESIRED_NAME="${INGRESS_NAME:-target-app}"
UPDATE_KUBECONFIG_SCRIPT="${REPO_ROOT}/scripts/update_kubeconfig.sh"
DELETE_INGRESS_SCRIPT="${REPO_ROOT}/scripts/onoff/delete_ingress.sh"
CLEANUP_SCRIPT="${REPO_ROOT}/scripts/wait_for_vpc_cleanup.sh"
EKS_REGION="${EKS_REGION:-${DEFAULT_EKS_REGION:-ap-northeast-2}}"

if [[ -x "${UPDATE_KUBECONFIG_SCRIPT}" ]]; then
  "${UPDATE_KUBECONFIG_SCRIPT}" "${TF_DIR}" "${EKS_REGION}" || true
fi

if [[ -x "${DELETE_INGRESS_SCRIPT}" ]]; then
  "${DELETE_INGRESS_SCRIPT}" "${DESIRED_NAMESPACE}" "${DESIRED_NAME}"
fi

cd "${TF_DIR}"

REFRESH_CMD=("${TF_CMD}" refresh -input=false)
DESTROY_CMD=("${TF_CMD}" destroy -input=false -auto-approve)
for file in "${VAR_FILES[@]}"; do
  REFRESH_CMD+=("-var-file=${file}")
  DESTROY_CMD+=("-var-file=${file}")
done

"${REFRESH_CMD[@]}"
"${DESTROY_CMD[@]}"

if [[ -x "${CLEANUP_SCRIPT}" ]]; then
  VPC_ID=$(terraform -chdir="${STATIC_TF_DIR}" output -raw vpc_id 2>/dev/null || true)
  if [[ "${VPC_ID}" == vpc-* ]]; then
    cleanup_services=${SERVICE_TAG_VALUES:-logs,api,dkr}
    SERVICE_TAG_VALUES="${cleanup_services}" "${CLEANUP_SCRIPT}" "${VPC_ID}"
  else
    echo "Skipping AWS cleanup wait; VPC ID not available."
  fi
fi
