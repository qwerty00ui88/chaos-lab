#!/bin/bash
set -euo pipefail

NAMESPACE=${1:-target-app}
NAME=${2:-target-app}
MAX_ATTEMPTS=${MAX_ATTEMPTS:-3}
SLEEP_SECONDS=${SLEEP_SECONDS:-10}

if ! command -v kubectl >/dev/null 2>&1; then
  echo "kubectl command not found" >&2
  exit 1
fi

echo "Attempting to delete ingress ${NAME} in namespace ${NAMESPACE}"
for attempt in $(seq 1 "${MAX_ATTEMPTS}"); do
  if kubectl delete ingress "${NAME}" -n "${NAMESPACE}" --wait=true --ignore-not-found; then
    echo "Ingress ${NAME} deleted successfully (attempt ${attempt})."
    exit 0
  fi

  echo "Ingress delete attempt ${attempt} failed; retrying in ${SLEEP_SECONDS}s..."
  sleep "${SLEEP_SECONDS}"
done

if kubectl get ingress "${NAME}" -n "${NAMESPACE}" >/dev/null 2>&1; then
  echo "Patching ingress ${NAME} to remove finalizers before retrying..."
  kubectl patch ingress "${NAME}" -n "${NAMESPACE}" --type=merge --patch '{"metadata":{"finalizers":[]}}' || true
  kubectl delete ingress "${NAME}" -n "${NAMESPACE}" --wait=false --ignore-not-found
fi

echo "Ingress delete command completed."
