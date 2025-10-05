module "eks" {
  count = var.enable_eks ? 1 : 0

  source = "../modules/eks"

  name            = local.cluster_name
  cluster_version = var.eks_version
  subnet_ids      = local.node_subnet_ids
  tags            = module.shared.default_tags
}

module "nodegroup" {
  count = var.enable_nodegroup && var.enable_eks ? 1 : 0

  depends_on = [module.eks]

  source = "../modules/nodegroup"

  cluster_name      = module.eks[0].name
  name              = local.nodegroup_name
  subnet_ids        = local.node_subnet_ids
  security_group_id = local.eks_node_security_group_id
  ami_type          = var.node_ami_type
  instance_types    = var.node_instance_types
  desired_size      = var.node_desired_size
  min_size          = var.node_min_size
  max_size          = var.node_max_size
  capacity_type     = var.node_capacity_type
  tags              = module.shared.default_tags
}

resource "aws_iam_openid_connect_provider" "eks" {
  count = var.enable_eks ? 1 : 0

  url             = local.eks_oidc_issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["9e99a48a9960b14926bb7f3b02e22da0afd10df6"]
}

resource "aws_iam_policy" "fluent_bit_logs" {
  count = var.enable_fluent_bit && var.enable_eks ? 1 : 0

  name        = "${module.shared.project_name}-${var.environment}-fluent-bit-logs"
  description = "CloudWatch Logs access for Fluent Bit"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = [
          "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:${var.cloudwatch_log_group_name != "" ? var.cloudwatch_log_group_name : "${module.shared.project_name}-${var.environment}-logs"}:*"
        ]
      }
    ]
  })
}

resource "aws_iam_role" "fluent_bit" {
  count = var.enable_fluent_bit && var.enable_eks ? 1 : 0

  name = "${module.shared.project_name}-${var.environment}-fluent-bit"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.eks[0].arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(local.eks_oidc_issuer, "https://", "")}:sub" = "system:serviceaccount:${var.fluent_bit_namespace}:${var.fluent_bit_service_account_name}"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "fluent_bit" {
  count = var.enable_fluent_bit && var.enable_eks ? 1 : 0

  role       = aws_iam_role.fluent_bit[0].name
  policy_arn = aws_iam_policy.fluent_bit_logs[0].arn
}

module "fluent_bit" {
  count = var.enable_fluent_bit && var.enable_eks ? 1 : 0

  depends_on = [module.eks, module.nodegroup]

  source = "../modules/helm_fluent_bit"

  providers = {
    kubernetes = kubernetes.eks
    helm       = helm.eks
  }

  iam_role_arn                 = aws_iam_role.fluent_bit[0].arn
  cloudwatch_log_group         = var.cloudwatch_log_group_name != "" ? var.cloudwatch_log_group_name : "${module.shared.project_name}-${var.environment}-logs"
  cloudwatch_log_stream_prefix = var.cloudwatch_log_stream_prefix
  region                       = var.region
  namespace                    = var.fluent_bit_namespace
  service_account_name         = var.fluent_bit_service_account_name
}
