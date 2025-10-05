module "cloudwatch_logs" {
  count = var.enable_cloudwatch_logs ? 1 : 0

  source = "../modules/cloudwatch_logs"

  name              = var.cloudwatch_log_group_name != "" ? var.cloudwatch_log_group_name : "${module.shared.project_name}-${var.environment}-logs"
  retention_in_days = var.cloudwatch_log_retention_in_days
  stream_names      = var.cloudwatch_log_stream_names
  kms_key_id        = var.cloudwatch_log_kms_key_id
  tags              = module.shared.default_tags
}