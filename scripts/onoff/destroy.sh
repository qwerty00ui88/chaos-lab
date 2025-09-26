#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TF_DIR="${ROOT_DIR}/../infra/onoff"
TF_CMD=${TF_CMD:-terraform}

VAR_FILES=("vars/base.tfvars" "vars/toggles.tfvars")

cd "${TF_DIR}"

CMD=("${TF_CMD}" destroy -auto-approve)
for file in "${VAR_FILES[@]}"; do
  CMD+=("-var-file=${file}")
done

"${CMD[@]}"
