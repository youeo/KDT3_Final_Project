# ==========================================
# ACM 인증서 생성 및 Route53 검증 설정
# ==========================================

# ACM 인증서 생성 및 요청 (us-east-1)
resource "aws_acm_certificate" "cert" {
  provider                  = aws.us_east_1
  domain_name               = "<YOUR_DOMAIN_NAME>"
  subject_alternative_names = ["*.<YOUR_DOMAIN_NAME>"]
  validation_method         = "DNS"

  tags = {
    Name = "my-certificate"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# 인증서 검증을 위한 DNS 레코드 생성
resource "aws_route53_record" "cert_validation_us" {
  provider = aws.us_east_1
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => dvo
  }
  allow_overwrite = true
  name            = each.value.resource_record_name
  records         = [each.value.resource_record_value]
  type            = each.value.resource_record_type
  zone_id         = data.aws_route53_zone.ajean.zone_id
  ttl             = 60
}

# 인증서 검증 완료 리소스
resource "aws_acm_certificate_validation" "cert_us" {
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for r in aws_route53_record.cert_validation_us : r.fqdn]
}

# AWS 리소스 상태 확인(Health Check) 생성
resource "aws_route53_health_check" "aws_service" {
  fqdn              = "www.${data.aws_route53_zone.ajean.name}"
  type              = "HTTPS"
  port              = 443
  resource_path     = "/"
  failure_threshold = "3"
  request_interval  = "30"
}

# ==========================================
# Azure IP 우회용 Route53 레코드
# ==========================================
resource "aws_route53_record" "azure_origin_dns" {
  zone_id = data.aws_route53_zone.ajean.zone_id
  name    = "origin-azure" # 자동으로 origin-azure.<YOUR_DOMAIN_NAME> 이 됩니다.
  type    = "A"
  ttl     = 60
  records = ["20.214.115.134"] # Azure 로드밸런서 IP
}


# ==========================================
# CloudFront 및 Route53 도메인 연결 설정
# ==========================================

resource "aws_cloudfront_origin_access_control" "s3_oac" {
  name                              = "s3-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# www.ajean.shop 도메인을 CloudFront에 연결
resource "aws_route53_record" "www" {
  zone_id = data.aws_route53_zone.ajean.zone_id
  name    = "www"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.distribution.domain_name
    zone_id                = aws_cloudfront_distribution.distribution.hosted_zone_id
    evaluate_target_health = false
  }
}



# CloudFront 디스트리뷰션 설정
resource "aws_cloudfront_distribution" "distribution" {
  enabled             = true
  default_root_object = "index.html"
  aliases             = ["www.<YOUR_DOMAIN_NAME>"]

  # [오리진 1] 메인 백엔드 (이관 단계에 따라 아래 주석을 켜고 끄기)
  origin {
    # --------------------------------==================================
    # [1단계 / 3단계 Failback] 평소 AWS 운영 및 장애 복구 시 아래 주석을 킴
    domain_name = replace(local.ingress_dns_name, "/^https?:\\/\\//", "")

    # [2단계] Azure 이관 준비가 완료되면 위를 주석 처리하고 아래 주석을 킴
    # domain_name = aws_route53_record.azure_origin_dns.fqdn
    # --------------------------------==================================

    origin_id = "my-app-origin"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  # [오리진 2] 대기실 (S3 정적 웹 호스팅 엔드포인트)
  origin {
    domain_name = "www.<YOUR_DOMAIN_NAME>.s3-website.ap-northeast-2.amazonaws.com"
    origin_id   = "S3-Website-Origin"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  # 오리진 그룹 생성 (Primary 장애 시 S3 대기실로 자동 우회)
  origin_group {
    origin_id = "failover-origin-group"

    failover_criteria {
      status_codes = [500, 502, 503, 504]
    }

    member {
      origin_id = "my-app-origin" # 1순위 타겟 (AWS 혹은 Azure)
    }
    member {
      origin_id = "S3-Website-Origin" # 2순위 타겟 (S3 대기실)
    }
  }

  # 라우팅 룰 설정 (오리진 그룹 지정)
  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "failover-origin-group"

    forwarded_values {
      query_string = true
      headers      = ["*"]
      cookies {
        forward = "all"
      }
    }
    viewer_protocol_policy = "redirect-to-https"
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.cert_us.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  restrictions {
    geo_restriction { restriction_type = "none" }
  }

  depends_on = [
    aws_acm_certificate_validation.cert_us,
    aws_cloudfront_origin_access_control.s3_oac
  ]
}