#!/bin/bash
set -euo pipefail

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:${PATH:-}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
TF_DIR="${REPO_ROOT}/infra/onoff"
TF_CMD=${TF_CMD:-terraform}

VAR_FILES=("vars/base.tfvars" "vars/toggles.tfvars")
MANIFEST_PATH="${REPO_ROOT}/target-app/k8s/ingress.yaml"
UPDATE_KUBECONFIG_SCRIPT="${REPO_ROOT}/scripts/update_kubeconfig.sh"
EKS_REGION="${EKS_REGION:-${DEFAULT_EKS_REGION:-ap-northeast-2}}"
INGRESS_NAMESPACE="${INGRESS_NAMESPACE:-target-app}"
INGRESS_NAME="${INGRESS_NAME:-target-app}"
INGRESS_WAIT_ATTEMPTS=${INGRESS_WAIT_ATTEMPTS:-30}
INGRESS_WAIT_SECONDS=${INGRESS_WAIT_SECONDS:-10}
RDS_PASSWORD_SSM_PARAMETER="${RDS_PASSWORD_SSM_PARAMETER:-}"

run_terraform() {
  local action=$1
  shift
  local cmd=("${TF_CMD}" "${action}" -input=false -auto-approve)
  for file in "${VAR_FILES[@]}"; do
    cmd+=("-var-file=${file}")
  done
  cmd+=("$@")
  "${cmd[@]}"
}

wait_for_ingress_hostname() {
  local attempt
  for attempt in $(seq 1 "${INGRESS_WAIT_ATTEMPTS}"); do
    local host
    host=$(kubectl -n "${INGRESS_NAMESPACE}" get ingress "${INGRESS_NAME}" \
      -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || true)
    host=$(printf '%s' "${host}" | tr -d '\r')
    if [[ -n "${host}" && "${host}" != "<no value>" ]]; then
      printf '%s' "${host}"
      return 0
    fi
    sleep "${INGRESS_WAIT_SECONDS}"
  done
  return 1
}

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

cd "${TF_DIR}"

run_terraform apply

if [[ -x "${UPDATE_KUBECONFIG_SCRIPT}" ]]; then
  "${UPDATE_KUBECONFIG_SCRIPT}" "${TF_DIR}" "${EKS_REGION}" || true
fi

if [[ ! -f "${MANIFEST_PATH}" ]]; then
  echo "Ingress manifest not found at ${MANIFEST_PATH}" >&2
  exit 1
fi

if ! command -v kubectl >/dev/null 2>&1; then
  echo "kubectl command not found" >&2
  exit 1
fi

kubectl apply -f "${MANIFEST_PATH}"

if [[ "${DISABLE_CLOUDFRONT_REAPPLY:-}" == "1" ]]; then
  echo "CloudFront origin override update skipped (DISABLE_CLOUDFRONT_REAPPLY=1)."
  exit 0
fi

if ingress_host=$(wait_for_ingress_hostname); then
  echo "Detected ingress hostname: ${ingress_host}"
  if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
    echo "ingress_host=${ingress_host}" >> "${GITHUB_OUTPUT}"
  fi
  if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
    printf 'Ingress hostname: %s\n' "${ingress_host}" >> "${GITHUB_STEP_SUMMARY}"
  fi
  run_terraform apply "-var=target_app_api_origin_domain_override=${ingress_host}"
else
  echo "Ingress hostname was not ready after $((INGRESS_WAIT_ATTEMPTS * INGRESS_WAIT_SECONDS))s; skipping CloudFront origin update." >&2
fi
