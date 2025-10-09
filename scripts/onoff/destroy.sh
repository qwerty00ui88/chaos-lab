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
RDS_PASSWORD_SSM_PARAMETER="${RDS_PASSWORD_SSM_PARAMETER:-}"

ensure_rds_password() {
  if [[ -n "${TF_VAR_rds_password:-}" ]]; then
    return 0
  fi

  if [[ -n "${RDS_PASSWORD_SSM_PARAMETER}" ]]; then
    if ! command -v aws >/dev/null 2>&1; then
      echo "aws CLI not found; cannot read ${RDS_PASSWORD_SSM_PARAMETER} from SSM." >&2
      exit 1
    fi

    local value
    if ! value=$(aws ssm get-parameter \
      --name "${RDS_PASSWORD_SSM_PARAMETER}" \
      --with-decryption \
      --query 'Parameter.Value' \
      --output text 2>/dev/null); then
      echo "Failed to fetch RDS password from SSM parameter ${RDS_PASSWORD_SSM_PARAMETER}." >&2
      exit 1
    fi

    if [[ -z "${value}" || "${value}" == "None" ]]; then
      echo "SSM parameter ${RDS_PASSWORD_SSM_PARAMETER} returned an empty value." >&2
      exit 1
    fi

    export TF_VAR_rds_password="${value}"
  fi

  if [[ -z "${TF_VAR_rds_password:-}" ]]; then
    echo "RDS password not provided. Set TF_VAR_rds_password or RDS_PASSWORD_SSM_PARAMETER." >&2
    exit 1
  fi
}

ensure_rds_password

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
