resource "aws_cloudwatch_log_group" "this" {
  name              = var.name
  retention_in_days = var.retention_in_days
  kms_key_id        = var.kms_key_id

  tags = merge(var.tags, {
    Name = var.name
  })
}

resource "aws_cloudwatch_log_stream" "this" {
  for_each = var.stream_names

  name           = each.value
  log_group_name = aws_cloudwatch_log_group.this.name
}
