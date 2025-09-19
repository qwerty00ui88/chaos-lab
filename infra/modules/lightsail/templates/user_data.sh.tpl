#!/bin/bash
set -euo pipefail

exec > >(tee /var/log/chaos-dashboard-bootstrap.log|logger -t user-data ) 2>&1

echo "[bootstrap] Updating packages"
apt-get update -y
apt-get install -y unzip curl jq ca-certificates gnupg lsb-release

# Install Docker
if ! command -v docker &>/dev/null; then
  echo "[bootstrap] Installing Docker"
  curl -fsSL https://get.docker.com | bash
  usermod -aG docker ubuntu || true
fi

# Install Terraform
TERRAFORM_VERSION="${terraform_version}"
if ! command -v terraform &>/dev/null || [[ "$(terraform version -json | jq -r '.terraform_version')" != "${terraform_version}" ]]; then
  echo "[bootstrap] Installing Terraform ${terraform_version}"
  curl -L "https://releases.hashicorp.com/terraform/${terraform_version}/terraform_${terraform_version}_linux_amd64.zip" -o /tmp/terraform.zip
  unzip -o /tmp/terraform.zip -d /usr/local/bin
  rm /tmp/terraform.zip
fi

# Install AWS CLI v2
if ! command -v aws &>/dev/null; then
  echo "[bootstrap] Installing AWS CLI v2"
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
  unzip -q /tmp/awscliv2.zip -d /tmp
  /tmp/aws/install
  rm -rf /tmp/aws /tmp/awscliv2.zip
fi

# Install kubectl
if ! command -v kubectl &>/dev/null; then
  echo "[bootstrap] Installing kubectl"
  curl -LO "https://dl.k8s.io/release/${kubectl_version}/bin/linux/amd64/kubectl"
  install -m 0755 kubectl /usr/local/bin/kubectl
  rm kubectl
fi

# Install Helm
if ! command -v helm &>/dev/null; then
  echo "[bootstrap] Installing Helm"
  curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

mkdir -p /opt/chaos-dashboard/scripts
chown -R ubuntu:ubuntu /opt/chaos-dashboard

cat <<'ENV' >/opt/chaos-dashboard/.env
AWS_REGION=${aws_region}
ECR_REGISTRY=${ecr_registry}
ECR_REPOSITORY_PREFIX=${ecr_repository_prefix}
EKS_CLUSTER_NAME=${eks_cluster_name}
ENV

cat <<'NOTE' >/opt/chaos-dashboard/README
Terraform/Helm bootstrap completed.
Place dashboard compose files or binaries under /opt/chaos-dashboard.
Scripts volume is ready for application deployment.
NOTE

systemctl enable docker
systemctl restart docker

su - ubuntu -c "mkdir -p ~/chaos-dashboard"

# Placeholder: actual docker compose deployment can be triggered manually or via CI.
echo "[bootstrap] Completed"
