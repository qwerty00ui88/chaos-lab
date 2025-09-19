#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <service-id> <image-tag> [namespace]" >&2
  exit 1
fi

SERVICE_ID="$1"
IMAGE_TAG="$2"
NAMESPACE="${3:-target-app}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CHART_DIR="${ROOT_DIR}/../target-app/charts/${SERVICE_ID}"

if [[ ! -d "${CHART_DIR}" ]]; then
  echo "Chart directory not found: ${CHART_DIR}" >&2
  exit 1
fi

ECR_REGISTRY=${ECR_REGISTRY:?"ECR_REGISTRY env not set"}
ECR_PREFIX=${ECR_REPOSITORY_PREFIX:?"ECR_REPOSITORY_PREFIX env not set"}

RELEASE_NAME="${SERVICE_ID}"
IMAGE_REPO="${ECR_REGISTRY}/${ECR_PREFIX}-${SERVICE_ID}"

helm upgrade --install "${RELEASE_NAME}" "${CHART_DIR}" \
  --namespace "${NAMESPACE}" \
  --create-namespace \
  --set image.repository="${IMAGE_REPO}" \
  --set image.tag="${IMAGE_TAG}"
