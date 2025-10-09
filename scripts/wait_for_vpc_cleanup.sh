#!/bin/bash
set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: $0 <vpc-id> [max_attempts] [sleep_seconds]" >&2
  echo "Optional env vars: SERVICE_TAG_VALUES=tag1,tag2 to limit checks to specific endpoint/service tags" >&2
  exit 1
fi

VPC_ID=$1
MAX_ATTEMPTS=${2:-20}
SLEEP_SECONDS=${3:-30}
SERVICE_TAG_VALUES=${SERVICE_TAG_VALUES:-}

normalize_count() {
  local value="$1"
  if [[ -z "$value" || "$value" == "None" ]]; then
    echo 0
  else
    echo "$value"
  fi
}

echo "⏳ Checking AWS cleanup for VPC ${VPC_ID}..."
for attempt in $(seq 1 "${MAX_ATTEMPTS}"); do
  eni_filters=("Name=vpc-id,Values=${VPC_ID}")
  vpce_filters=("Name=vpc-id,Values=${VPC_ID}")

  if [[ -n "$SERVICE_TAG_VALUES" ]]; then
    eni_filters+=("Name=tag:Service,Values=${SERVICE_TAG_VALUES}")
    vpce_filters+=("Name=tag:Service,Values=${SERVICE_TAG_VALUES}")
  fi

  eni_filter_args=()
  for f in "${eni_filters[@]}"; do
    eni_filter_args+=(--filters "$f")
  done

  vpce_filter_args=()
  for f in "${vpce_filters[@]}"; do
    vpce_filter_args+=(--filters "$f")
  done

  eni_count_raw=$(aws ec2 describe-network-interfaces \
    "${eni_filter_args[@]}" \
    --query 'length(NetworkInterfaces[?Status!=`available`])' \
    --output text || echo "error")

  vpce_count_raw=$(aws ec2 describe-vpc-endpoints \
    "${vpce_filter_args[@]}" \
    --query 'length(VpcEndpoints[?State!=`deleted`])' \
    --output text || echo "error")

  if [[ "$eni_count_raw" == "error" || "$vpce_count_raw" == "error" ]]; then
    echo "Failed to query AWS APIs; ensure credentials are available." >&2
    exit 1
  fi

  eni_count=$(normalize_count "$eni_count_raw")
  vpce_count=$(normalize_count "$vpce_count_raw")

  echo "Attempt ${attempt}/${MAX_ATTEMPTS}: ENI=${eni_count} VPCE=${vpce_count}"

  if [[ "$eni_count" -eq 0 && "$vpce_count" -eq 0 ]]; then
    echo "✅ AWS cleanup complete for VPC ${VPC_ID}."
    exit 0
  fi

  if [[ "$attempt" -lt "$MAX_ATTEMPTS" ]]; then
    sleep "${SLEEP_SECONDS}"
  fi
done

echo "⚠️ Timed out waiting for ENI/VPCE cleanup in VPC ${VPC_ID}." >&2
exit 1
