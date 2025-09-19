#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT_DEPLOY="${ROOT_DIR}/helm/deploy-service.sh"
SCRIPT_UNDEPLOY="${ROOT_DIR}/helm/undeploy-service.sh"

IMAGE_TAG=${IMAGE_TAG:-$(git -C "${ROOT_DIR}/.." rev-parse --short HEAD)}
NAMESPACE=${KUBE_NAMESPACE:-target-app}

SERVICES=(svc-user svc-catalog svc-order)

for svc in "${SERVICES[@]}"; do
  "${SCRIPT_DEPLOY}" "${svc}" "${IMAGE_TAG}" "${NAMESPACE}"
  echo "Deployed ${svc} with tag ${IMAGE_TAG}"
done
