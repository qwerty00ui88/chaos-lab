#!/usr/bin/env bash
set -euo pipefail

TF_DIR="${1:-infra/onoff}"
DEFAULT_REGION="${2:-ap-northeast-2}"

# Attempt to pull outputs; skip if state is not yet initialized.
if ! outputs_json=$(terraform -chdir="$TF_DIR" output -json 2>/dev/null); then
  echo "EKS cluster not available yet; skipping kubeconfig update."
  exit 0
fi

if [[ -z "$outputs_json" ]]; then
  echo "EKS cluster not available yet; skipping kubeconfig update."
  exit 0
fi

cluster_region=$(OUTPUTS="$outputs_json" python3 - <<'PY'
import json
import os

def get_value(data, key):
    try:
        return data.get(key, {}).get("value") or ""
    except AttributeError:
        return ""

raw = os.environ.get("OUTPUTS", "{}")
try:
    parsed = json.loads(raw)
except json.JSONDecodeError:
    parsed = {}

print(get_value(parsed, "eks_cluster_name"))
print(get_value(parsed, "eks_cluster_region"))
PY
)

cluster=$(printf '%s' "$cluster_region" | sed -n '1p')
region=$(printf '%s' "$cluster_region" | sed -n '2p')

if [[ -z "$cluster" ]]; then
  echo "EKS cluster not available yet; skipping kubeconfig update."
  exit 0
fi

if [[ -z "$region" ]]; then
  region="$DEFAULT_REGION"
fi

echo "Updating kubeconfig for $cluster (region $region)"
aws eks update-kubeconfig --name "$cluster" --region "$region" >/dev/null
