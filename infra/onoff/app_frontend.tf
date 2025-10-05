# S3 버킷 (Public Access 차단 유지)
resource "aws_s3_bucket" "target_app_frontend" {
  count  = var.enable_eks ? 1 : 0
  bucket = "${module.shared.project_name}-${var.environment}-target-app-frontend"
}

# Block Public Access
resource "aws_s3_bucket_public_access_block" "frontend" {
  count  = var.enable_eks ? 1 : 0
  bucket = aws_s3_bucket.target_app_frontend[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# OAC 생성
resource "aws_cloudfront_origin_access_control" "frontend" {
  count = var.enable_eks ? 1 : 0

  name                              = "${module.shared.project_name}-${var.environment}-oac"
  description                       = "OAC for target-app frontend"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# API 요청을 위한 Origin Request 정책 (헤더/쿠키/쿼리 전달)
resource "aws_cloudfront_origin_request_policy" "api_policy" {
  count = var.enable_eks ? 1 : 0

  name    = "${module.shared.project_name}-${var.environment}-api-origin-policy"
  comment = "Forward headers/cookies/query strings for API calls"

  cookies_config {
    cookie_behavior = "all"
  }

  headers_config {
    header_behavior = "whitelist"
    headers {
      items = ["Origin"]
    }
  }

  query_strings_config {
    query_string_behavior = "all"
  }
}

resource "aws_cloudfront_cache_policy" "api_cache_disabled" {
  count = var.enable_eks ? 1 : 0

  name    = "${module.shared.project_name}-${var.environment}-api-cache-disabled"
  comment = "Disable caching for API forwarding"

  default_ttl = 0
  max_ttl     = 0
  min_ttl     = 0

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "none"
    }

    headers_config {
      header_behavior = "none"
    }

    query_strings_config {
      query_string_behavior = "none"
    }
  }
}

# CloudFront 배포
locals {
  target_app_api_origin_domain = var.enable_eks && var.enable_aws_load_balancer_controller ? kubernetes_ingress_v1.target_app[0].status[0].load_balancer[0].ingress[0].hostname : (var.enable_alb ? module.alb[0].alb_dns_name : "")
}

resource "aws_cloudfront_distribution" "target_app_frontend" {
  count = var.enable_eks ? 1 : 0

  # S3 정적 컨텐츠 오리진
  origin {
    domain_name              = aws_s3_bucket.target_app_frontend[0].bucket_regional_domain_name
    origin_id                = "S3-${aws_s3_bucket.target_app_frontend[0].id}"
    origin_access_control_id = aws_cloudfront_origin_access_control.frontend[0].id
  }

  # ALB API 백엔드 오리진
  origin {
    origin_id   = "ALB-${module.shared.project_name}-${var.environment}"
    domain_name = local.target_app_api_origin_domain

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  # 기본 동작: S3로 정적 파일 요청 전달
  default_cache_behavior {
    target_origin_id       = "S3-${aws_s3_bucket.target_app_frontend[0].id}"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]
    # AWS 관리형 캐시 최적화 정책 사용
    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6" # Managed-CachingOptimized
  }

  # 추가 동작: /api/* 요청을 ALB로 전달
  ordered_cache_behavior {
    path_pattern     = "/api/*"
    target_origin_id = "ALB-${module.shared.project_name}-${var.environment}"

    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods  = ["GET", "HEAD"] # 실제 캐시는 아래 정책에 의해 제어됨

    # Disable caching via custom policy + forward details with origin request policy
    cache_policy_id          = aws_cloudfront_cache_policy.api_cache_disabled[0].id
    origin_request_policy_id = aws_cloudfront_origin_request_policy.api_policy[0].id
  }

  price_class = "PriceClass_200"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  depends_on = [
    kubernetes_ingress_v1.target_app
  ]
}


# S3 버킷 정책 (CloudFront OAC만 접근 허용)
resource "aws_s3_bucket_policy" "frontend" {
  count  = var.enable_eks ? 1 : 0
  bucket = aws_s3_bucket.target_app_frontend[0].id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "cloudfront.amazonaws.com"
        },
        Action   = "s3:GetObject",
        Resource = "${aws_s3_bucket.target_app_frontend[0].arn}/*",
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.target_app_frontend[0].arn
          }
        }
      }
    ]
  })
}

resource "aws_s3_object" "target_app_frontend_files" {
  for_each = var.enable_eks ? toset(local.frontend_files) : toset([])

  bucket       = aws_s3_bucket.target_app_frontend[0].id
  key          = each.value
  source       = "${local.frontend_dist_path}/${each.value}"
  content_type = try(local.mime_types[regex("\\.[^.]+$$", each.value)], "application/octet-stream")
  etag         = filemd5("${local.frontend_dist_path}/${each.value}")
}
