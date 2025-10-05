#!/bin/bash
set -o pipefail

CLUSTER_NAME="${cluster_name}"
API_SERVER="${cluster_endpoint}"
CERTIFICATE_AUTHORITY="${cluster_ca}"

NODE_LABELS="${join(",", [for k, v in node_labels : format("%s=%s", k, v)])}"
NODE_TAINTS="${join(",", node_taints)}"
KUBELET_EXTRA_ARGS="${kubelet_extra_args}"

BOOTSTRAP_ARGS=(
  "$CLUSTER_NAME"
  --apiserver-endpoint "$API_SERVER"
  --b64-cluster-ca "$CERTIFICATE_AUTHORITY"
)

if [ -n "$NODE_LABELS" ]; then
  BOOTSTRAP_ARGS+=(--node-labels "$NODE_LABELS")
fi

if [ -n "$NODE_TAINTS" ]; then
  BOOTSTRAP_ARGS+=(--register-with-taints "$NODE_TAINTS")
fi

if [ -n "$KUBELET_EXTRA_ARGS" ]; then
  BOOTSTRAP_ARGS+=(--kubelet-extra-args "$KUBELET_EXTRA_ARGS")
fi

/etc/eks/bootstrap.sh "$${BOOTSTRAP_ARGS[@]}"
