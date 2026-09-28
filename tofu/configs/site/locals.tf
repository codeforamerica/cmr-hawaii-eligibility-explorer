locals {
  # Mirrors the s3-bucket module's own naming so the bucket ARN can be built
  # before the module is evaluated
  bucket_name = join("-", compact([var.project, var.state, var.environment, var.application]))

  prefix = local.bucket_name

  fqdn = join(".", compact([var.subdomain, var.domain]))

  content_path = abspath("${path.module}/${var.content_file}")

  logging_bucket = coalesce(var.logging_bucket, try(module.logging["this"].bucket, null))

  hosted_zone_id = (var.create_hosted_zone
    ? aws_route53_zone.domain["this"].zone_id
    : data.aws_route53_zone.domain["this"].zone_id
  )

  template_dir = "${path.module}/templates"
}