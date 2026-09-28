output "bucket_name" {
  description = "Name of the S3 bucket holding the site content."
  value       = module.content.name
}

output "distribution_id" {
  description = <<-EOT
    CloudFront distribution ID. Use this to invalidate the cache by hand:
    `aws cloudfront create-invalidation --distribution-id <id> --paths '/*'`.
    EOT
  value       = aws_cloudfront_distribution.site.id
}

output "endpoint_url" {
  description = "Public URL for the site."
  value       = "https://${local.fqdn}"
}

output "hosted_zone_name_servers" {
  description = <<-EOT
    Name servers for the hosted zone created by this configuration. Null unless
    `create_hosted_zone` is true. Give these to whoever owns the parent zone so
    they can add the delegating NS record.
    EOT
  value       = try(aws_route53_zone.domain["this"].name_servers, null)
}

output "logging_bucket" {
  description = "Bucket receiving S3 server access logs for the content bucket."
  value       = local.logging_bucket
}
