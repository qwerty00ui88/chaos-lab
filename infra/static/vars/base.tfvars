region      = "ap-northeast-2"
aws_profile = "default"
environment = "dev"

enable_lightsail = true

# Lightsail dashboard bootstrap configuration
lightsail_ecr_registry          = "446447036578.dkr.ecr.ap-northeast-2.amazonaws.com"
lightsail_ecr_repository_prefix = "chaos-lab"
lightsail_eks_cluster_name      = "chaos-lab-dev"
lightsail_dashboard_repo_url    = "https://github.com/sohuiham/chaos-lab.git"
lightsail_dashboard_repo_branch = "main"
lightsail_dashboard_clone_path  = "/opt/chaos-dashboard/app"
lightsail_dashboard_compose_path = "lab-dashboard/deploy/lightsail/docker-compose.yml"
