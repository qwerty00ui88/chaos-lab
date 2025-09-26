#!/usr/bin/env bash
set -euo pipefail

DASHBOARD_ROOT=${DASHBOARD_ROOT:-/opt/chaos-dashboard}
ENV_FILE="${DASHBOARD_ROOT}/.env"

if [[ ! -d "${DASHBOARD_ROOT}" ]]; then
  echo "[ERROR] Dashboard root '${DASHBOARD_ROOT}' not found. Set DASHBOARD_ROOT or run on the dashboard host." >&2
  exit 1
fi

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "[ERROR] Environment file '${ENV_FILE}' not found. Run bootstrap first." >&2
  exit 1
fi

# shellcheck disable=SC1090
set -a
source "${ENV_FILE}"
set +a

AWS_REGION_VALUE=${AWS_REGION:-${AWS_DEFAULT_REGION:-}}
if [[ -z "${AWS_REGION_VALUE}" ]]; then
  echo "[ERROR] AWS_REGION is not set in ${ENV_FILE} or environment." >&2
  exit 1
fi

if [[ -z "${ECR_REGISTRY:-}" ]]; then
  echo "[ERROR] ECR_REGISTRY is not set in ${ENV_FILE}." >&2
  exit 1
fi

echo "[dashboard] Logging in to ECR ${ECR_REGISTRY} (${AWS_REGION_VALUE})"
aws ecr get-login-password --region "${AWS_REGION_VALUE}" | docker login --username AWS --password-stdin "${ECR_REGISTRY}"

echo "[dashboard] Updating containers under ${DASHBOARD_ROOT}"
cd "${DASHBOARD_ROOT}"

if [[ $# -gt 0 ]]; then
  echo "[dashboard] Pulling services: $*"
  docker compose pull "$@"
  echo "[dashboard] Restarting services: $*"
  docker compose up -d "$@"
else
  docker compose pull
  docker compose up -d
fi

docker compose ps
