region      = "ap-northeast-2"
aws_profile = null

enable_dashboard_instance = true

dashboard_instance_type = "t3.small"
dashboard_key_pair_name = null
# dashboard_allowed_cidrs = ["0.0.0.0/0"]

# Dashboard bootstrap configuration
dashboard_ecr_registry          = "446447036578.dkr.ecr.ap-northeast-2.amazonaws.com"
dashboard_ecr_repository_prefix = "chaos-lab"
dashboard_repo_url              = "https://github.com/qwerty00ui88/chaos-lab.git"
dashboard_clone_path            = "/opt/chaos-dashboard/app"
dashboard_compose_path          = "lab-dashboard/deploy/dashboard/docker-compose.yml"
dashboard_terraform_client_tag  = "latest"
dashboard_chaos_injector_tag    = "latest"
dashboard_log_streamer_tag      = "latest"
dashboard_frontend_tag          = "latest"
