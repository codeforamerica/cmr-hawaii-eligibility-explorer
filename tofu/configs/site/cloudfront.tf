resource "aws_cloudfront_origin_access_control" "site" {
  name                              = local.prefix
  description                       = "Authorize CloudFront to read the ${var.application} content bucket."
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# Security headers the origin can't set, since S3 serves the object as-is.
# The page is self-contained (inline <style>, no external requests), so the CSP
# only has to allow inline styles and scripts.
resource "aws_cloudfront_response_headers_policy" "site" {
  name    = local.prefix
  comment = "Security headers for the ${var.application} static site."

  security_headers_config {
    content_type_options {
      override = true
    }

    frame_options {
      frame_option = "DENY"
      override     = true
    }

    referrer_policy {
      referrer_policy = "strict-origin-when-cross-origin"
      override        = true
    }

    strict_transport_security {
      access_control_max_age_sec = 31536000
      include_subdomains         = true
      preload                    = true
      override                   = true
    }

    content_security_policy {
      content_security_policy = join("; ", [
        "default-src 'none'",
        "style-src 'self' 'unsafe-inline'",
        "script-src 'self' 'unsafe-inline'",
        "img-src 'self' data:",
        "font-src 'self' data:",
        "base-uri 'none'",
        "form-action 'none'",
        "frame-ancestors 'none'",
      ])
      override = true
    }
  }
}

#trivy:ignore:AVD-AWS-0010
resource "aws_cloudfront_distribution" "site" {
  enabled             = true
  comment             = "Hawaii Clean Slate eligibility explorer."
  is_ipv6_enabled     = true
  aliases             = [local.fqdn]
  price_class         = "PriceClass_100"
  default_root_object = "index.html"
  web_acl_id          = var.enable_waf ? aws_wafv2_web_acl.site["this"].arn : null

  origin {
    domain_name              = "${module.content.name}.s3.us-east-1.amazonaws.com"
    origin_id                = local.prefix
    origin_access_control_id = aws_cloudfront_origin_access_control.site.id
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.prefix
    compress         = true

    viewer_protocol_policy = "redirect-to-https"

    cache_policy_id            = "658327ea-f89d-4fab-a63d-7e88639e58f6"
    response_headers_policy_id = aws_cloudfront_response_headers_policy.site.id
  }

  custom_error_response {
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 10
  }

  custom_error_response {
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 10
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.site.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}

# CloudFront caches the object for up to 24 hours by default, so republishing
# the HTML without an invalidation would not be visible for a day.
resource "terraform_data" "invalidation" {
  triggers_replace = [aws_s3_object.index.etag]

  provisioner "local-exec" {
    command = join(" ", [
      "aws cloudfront create-invalidation",
      "--distribution-id ${aws_cloudfront_distribution.site.id}",
      "--paths '/*'",
    ])
  }
}