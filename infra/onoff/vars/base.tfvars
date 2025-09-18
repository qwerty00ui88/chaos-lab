# Base variables for the toggle stack. Adjust as needed per environment.
region      = "ap-northeast-2"
aws_profile = "default"
environment = "dev"
eks_version = "1.30"

node_instance_types = ["t3.small"]
node_capacity_type  = "ON_DEMAND"
node_desired_size   = 0
node_min_size       = 0
node_max_size       = 2

alb_listener_port     = 80
alb_listener_protocol = "HTTP"
alb_target_port       = 80
alb_health_check_path = "/health"

rds_engine            = "mysql"
rds_engine_version    = "8.0"
rds_instance_class    = "db.t3.micro"
rds_allocated_storage = 20
rds_db_name           = "chaoslab"
rds_username          = "admin"
# TODO: Override via tfvars or environment variable before applying.
rds_password = "change-me-please"
