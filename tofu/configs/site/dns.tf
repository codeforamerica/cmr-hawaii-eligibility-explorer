# Only created when this account owns a zone delegated for the site. Otherwise
# the zone is looked up in data.tf.
#
# The parent zone (dev.codeforamerica.app) must delegate NS records to this
# zone as a one-time manual step after the first apply. The parent is created
# by shared-services-infra in an account this configuration does not run in,
# so its owner has to add the records from the `hosted_zone_name_servers`
# output. Until they exist, the certificate below stays pending and
# aws_acm_certificate_validation.site blocks the progression of tofu apply.
resource "aws_route53_zone" "domain" {
  for_each = var.create_hosted_zone ? toset(["this"]) : toset([])

  name    = var.domain
  comment = "Delegated zone for the ${var.application} static site."
}

resource "aws_acm_certificate" "site" {
  domain_name       = local.fqdn
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "validation" {
  for_each = {
    for option in aws_acm_certificate.site.domain_validation_options :
    option.domain_name => {
      name   = option.resource_record_name
      record = option.resource_record_value
      type   = option.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = local.hosted_zone_id
}

resource "aws_acm_certificate_validation" "site" {
  certificate_arn         = aws_acm_certificate.site.arn
  validation_record_fqdns = [for record in aws_route53_record.validation : record.fqdn]
}

resource "aws_route53_record" "site" {
  for_each = toset(["A", "AAAA"])

  name    = local.fqdn
  type    = each.value
  zone_id = local.hosted_zone_id

  alias {
    evaluate_target_health = false
    name                   = aws_cloudfront_distribution.site.domain_name
    zone_id                = aws_cloudfront_distribution.site.hosted_zone_id
  }
}