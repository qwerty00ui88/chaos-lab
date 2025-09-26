#!/usr/bin/env bash
set -euo pipefail

# Ensure CLI tools installed under /usr/local/bin are visible when the script
# runs under SSM or non-login shells.
export PATH="/usr/local/bin:/usr/bin:/bin:${PATH}"

usage() {
  cat <<'EOF'
Usage: update-dashboard-instance.sh [options] [SERVICE...]

Options:
  --all-tag TAG                 Override all dashboard image tags with TAG
  --terraform-client-tag TAG    Override terraform-client image tag
  --chaos-injector-tag TAG      Override chaos-injector image tag
  --log-streamer-tag TAG        Override log-streamer image tag
  --frontend-tag TAG            Override frontend image tag
  --no-repo-sync                Skip git pull/rsync before updating containers
  -h, --help                    Show this help message

Any remaining arguments are passed as service names to docker compose.
EOF
}

update_env_var() {
  local var="$1"
  local value="$2"
  local file="$3"

  if [[ -z "${value}" ]]; then
    return 0
  fi

  if grep -q "^${var}=" "${file}"; then
    awk -v v="${var}" -v val="${value}" 'BEGIN{FS=OFS="="} $1==v {$2=val} {print}' "${file}" >"${file}.tmp"
    mv "${file}.tmp" "${file}"
  else
    printf '%s=%s\n' "${var}" "${value}" >>"${file}"
  fi
}

SERVICES=()
ALL_TAG=""
TERRAFORM_TAG=""
CHAOS_TAG=""
LOG_TAG=""
FRONTEND_TAG=""
SYNC_REPO=true

while [[ $# -gt 0 ]]; do
  case "$1" in
    --all-tag)
      [[ $# -lt 2 ]] && { echo "[ERROR] --all-tag requires a value" >&2; exit 1; }
      ALL_TAG="$2"
      shift 2
      ;;
    --terraform-client-tag)
      [[ $# -lt 2 ]] && { echo "[ERROR] --terraform-client-tag requires a value" >&2; exit 1; }
      TERRAFORM_TAG="$2"
      shift 2
      ;;
    --chaos-injector-tag)
      [[ $# -lt 2 ]] && { echo "[ERROR] --chaos-injector-tag requires a value" >&2; exit 1; }
      CHAOS_TAG="$2"
      shift 2
      ;;
    --log-streamer-tag)
      [[ $# -lt 2 ]] && { echo "[ERROR] --log-streamer-tag requires a value" >&2; exit 1; }
      LOG_TAG="$2"
      shift 2
      ;;
    --frontend-tag)
      [[ $# -lt 2 ]] && { echo "[ERROR] --frontend-tag requires a value" >&2; exit 1; }
      FRONTEND_TAG="$2"
      shift 2
      ;;
    --no-repo-sync)
      SYNC_REPO=false
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --)
      shift
      while [[ $# -gt 0 ]]; do
        SERVICES+=("$1")
        shift
      done
      break
      ;;
    *)
      SERVICES+=("$1")
      shift
      ;;
  esac
done

if [[ -n "${ALL_TAG}" ]]; then
  TERRAFORM_TAG="${TERRAFORM_TAG:-${ALL_TAG}}"
  CHAOS_TAG="${CHAOS_TAG:-${ALL_TAG}}"
  LOG_TAG="${LOG_TAG:-${ALL_TAG}}"
  FRONTEND_TAG="${FRONTEND_TAG:-${ALL_TAG}}"
fi

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

REPO_ROOT=${DASHBOARD_REPO_ROOT:-}
REPO_BRANCH=${DASHBOARD_REPO_BRANCH:-${dashboard_repo_branch:-main}}

if ${SYNC_REPO} && [[ -n "${REPO_ROOT}" && -d "${REPO_ROOT}" ]]; then
  if [[ -d "${REPO_ROOT}/.git" ]]; then
    echo "[dashboard] Syncing repository at ${REPO_ROOT} (branch ${REPO_BRANCH})"
    su - ubuntu -c "cd '${REPO_ROOT}' && git fetch --all --prune && git checkout '${REPO_BRANCH}' && git reset --hard 'origin/${REPO_BRANCH}'"
  else
    echo "[dashboard] Repository root '${REPO_ROOT}' is missing .git directory; skipping git sync" >&2
  fi

  if [[ -d "${REPO_ROOT}/scripts" ]]; then
    echo "[dashboard] Syncing scripts from repository"
    rsync -a --delete "${REPO_ROOT}/scripts/" "${DASHBOARD_ROOT}/scripts/"
    chown -R ubuntu:ubuntu "${DASHBOARD_ROOT}/scripts"
  fi

  if [[ -d "${REPO_ROOT}/infra" ]]; then
    echo "[dashboard] Syncing infra assets from repository"
    rsync -a --delete "${REPO_ROOT}/infra/" "${DASHBOARD_ROOT}/infra/"
    chown -R ubuntu:ubuntu "${DASHBOARD_ROOT}/infra"
  fi
fi

apply_tag() {
  local var_name="$1"
  local value="$2"
  if [[ -n "${value}" ]]; then
    echo "[dashboard] Setting ${var_name}=${value}"
    export "${var_name}=${value}"
    update_env_var "${var_name}" "${value}" "${ENV_FILE}"
  fi
}

apply_tag "TERRAFORM_CLIENT_TAG" "${TERRAFORM_TAG}"
apply_tag "CHAOS_INJECTOR_TAG" "${CHAOS_TAG}"
apply_tag "LOG_STREAMER_TAG" "${LOG_TAG}"
apply_tag "FRONTEND_TAG" "${FRONTEND_TAG}"

echo "[dashboard] Logging in to ECR ${ECR_REGISTRY} (${AWS_REGION_VALUE})"
aws ecr get-login-password --region "${AWS_REGION_VALUE}" | docker login --username AWS --password-stdin "${ECR_REGISTRY}"

echo "[dashboard] Updating containers under ${DASHBOARD_ROOT}"
cd "${DASHBOARD_ROOT}"

if [[ ${#SERVICES[@]} -gt 0 ]]; then
  echo "[dashboard] Pulling services: ${SERVICES[*]}"
  docker compose pull "${SERVICES[@]}"
  echo "[dashboard] Restarting services: ${SERVICES[*]}"
  docker compose up -d "${SERVICES[@]}"
else
  docker compose pull
  docker compose up -d
fi

docker compose ps
