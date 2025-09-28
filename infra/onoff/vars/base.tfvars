region      = "ap-northeast-2"
aws_profile = "default"
eks_version = "1.30"

# CloudWatch Logs / Fluent Bit defaults
cloudwatch_log_group_name        = ""
cloudwatch_log_retention_in_days = 1
cloudwatch_log_stream_names      = [
  "svc-user",
  "svc-catalog",
  "svc-order"
]
cloudwatch_log_stream_prefix     = "svc-"
fluent_bit_namespace             = "aws-for-fluent-bit"
fluent_bit_service_account_name  = "aws-for-fluent-bit"


