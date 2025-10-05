module "rds" {
  count = var.enable_rds ? 1 : 0

  source = "../modules/rds"

  identifier              = "${module.shared.project_name}-${var.environment}-db"
  engine                  = var.rds_engine
  engine_version          = var.rds_engine_version
  instance_class          = var.rds_instance_class
  allocated_storage       = var.rds_allocated_storage
  db_name                 = var.rds_db_name
  username                = var.rds_username
  password                = var.rds_password
  multi_az                = var.rds_multi_az
  subnet_ids              = local.db_subnet_ids
  security_group_ids      = local.rds_security_group_id == null ? [] : [local.rds_security_group_id]
  backup_retention_period = var.rds_backup_retention_period
  maintenance_window      = var.rds_maintenance_window
  backup_window           = var.rds_backup_window
  tags                    = module.shared.default_tags
}