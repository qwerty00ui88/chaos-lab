#!/bin/sh
set -eu

exec >/var/log/chaos-dashboard-bootstrap.log 2>&1
logger -t user-data "chaos-dashboard bootstrap starting"

echo "[bootstrap] Updating packages"
apt-get update -y
apt-get install -y unzip curl jq ca-certificates gnupg lsb-release git rsync

echo "[bootstrap] Installing Docker"
curl -fsSL https://get.docker.com | sh
usermod -aG docker ubuntu || true

echo "[bootstrap] Installing Terraform ${terraform_version}"
curl -L "https://releases.hashicorp.com/terraform/${terraform_version}/terraform_${terraform_version}_linux_amd64.zip" -o /tmp/terraform.zip
unzip -o /tmp/terraform.zip -d /usr/local/bin
rm /tmp/terraform.zip

echo "[bootstrap] Installing AWS CLI v2"
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
unzip -q /tmp/awscliv2.zip -d /tmp
/tmp/aws/install
rm -rf /tmp/aws /tmp/awscliv2.zip

echo "[bootstrap] Installing kubectl ${kubectl_version}"
curl -LO "https://dl.k8s.io/release/${kubectl_version}/bin/linux/amd64/kubectl"
install -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl

echo "[bootstrap] Installing Helm"
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

mkdir -p /opt/chaos-dashboard/scripts
chown -R ubuntu:ubuntu /opt/chaos-dashboard

cat <<'ENV' >/opt/chaos-dashboard/.env
AWS_REGION=${aws_region}
ECR_REGISTRY=${ecr_registry}
ECR_REPOSITORY_PREFIX=${ecr_repository_prefix}
EKS_CLUSTER_NAME=${eks_cluster_name}
DASHBOARD_REPO_ROOT=${dashboard_clone_path}
TERRAFORM_CLIENT_TAG=${terraform_client_tag}
CHAOS_INJECTOR_TAG=${chaos_injector_tag}
LOG_STREAMER_TAG=${log_streamer_tag}
FRONTEND_TAG=${frontend_tag}
ENV

cat <<'NOTE' >/opt/chaos-dashboard/README
Terraform/Helm bootstrap completed.
Place dashboard compose files or binaries under /opt/chaos-dashboard.
Scripts volume is ready for application deployment.
NOTE

systemctl enable docker
systemctl restart docker

cat <<SCRIPT >/tmp/chaos-dashboard-bootstrap.sh
#!/bin/sh
set -eu

REPO_URL="${dashboard_repo_url}"
REPO_BRANCH="${dashboard_repo_branch}"
CLONE_PATH="${dashboard_clone_path}"
COMPOSE_PATH="${dashboard_compose_path}"

CLONE_PARENT="$(dirname "$CLONE_PATH")"
mkdir -p "$CLONE_PARENT"

if [ -d "$${CLONE_PATH}/.git" ]; then
  echo "[bootstrap] Updating existing dashboard repository"
  cd "$${CLONE_PATH}"
  git fetch --all --prune
  git checkout "$${REPO_BRANCH}"
  git reset --hard "origin/$${REPO_BRANCH}"
else
  echo "[bootstrap] Cloning dashboard repository"
  rm -rf "$${CLONE_PATH}"
  git clone --branch "$${REPO_BRANCH}" "$${REPO_URL}" "$${CLONE_PATH}"
fi

case "$COMPOSE_PATH" in
  /*)
    COMPOSE_SRC="$COMPOSE_PATH"
    ;;
  *)
    COMPOSE_SRC="$CLONE_PATH/$COMPOSE_PATH"
    ;;
esac

ASSET_DIR="$(dirname "$COMPOSE_SRC")"

if [ -d "$${CLONE_PATH}/scripts" ]; then
  echo "[bootstrap] Syncing scripts directory"
  rsync -a --delete "$${CLONE_PATH}/scripts/" /opt/chaos-dashboard/scripts/
  chown -R ubuntu:ubuntu /opt/chaos-dashboard/scripts
fi

if [ -d "$${CLONE_PATH}/infra" ]; then
  echo "[bootstrap] Syncing infra directory"
  rsync -a --delete "$${CLONE_PATH}/infra/" /opt/chaos-dashboard/infra/
  chown -R ubuntu:ubuntu /opt/chaos-dashboard/infra
fi

if [ -f "$COMPOSE_SRC" ]; then
  echo "[bootstrap] Deploying docker compose from $COMPOSE_SRC"
  cp "$COMPOSE_SRC" /opt/chaos-dashboard/docker-compose.yml
  chown ubuntu:ubuntu /opt/chaos-dashboard/docker-compose.yml
  if [ -f "$ASSET_DIR/nginx.conf" ]; then
    cp "$ASSET_DIR/nginx.conf" /opt/chaos-dashboard/nginx.conf
    chown ubuntu:ubuntu /opt/chaos-dashboard/nginx.conf
  fi
  cd /opt/chaos-dashboard
  docker compose pull || true
  if ! docker compose up -d; then
    echo "[bootstrap] docker compose up failed (missing images?) - continuing" >&2
  fi
else
  echo "[bootstrap] Compose file not found at $COMPOSE_SRC; skipping auto start"
fi
SCRIPT

chmod +x /tmp/chaos-dashboard-bootstrap.sh
su - ubuntu -c /tmp/chaos-dashboard-bootstrap.sh
rm -f /tmp/chaos-dashboard-bootstrap.sh

logger -t user-data "chaos-dashboard bootstrap completed"
