#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <service-id> [namespace]" >&2
  exit 1
fi

SERVICE_ID="$1"
NAMESPACE="${2:-target-app}"

helm uninstall "${SERVICE_ID}" --namespace "${NAMESPACE}" || true
