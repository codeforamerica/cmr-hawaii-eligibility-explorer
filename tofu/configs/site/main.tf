# State lives in the backend cmr-infra's foundation layer already created in
# this account. There is only one environment, so these values are written out
# rather than supplied at init.
terraform {
  backend "s3" {
    bucket         = "clear-my-record-development-tfstate"
    key            = "hi-eligibility-explorer-site.tfstate"
    region         = "us-east-1"
    dynamodb_table = "development.tfstate"
  }
}

# The s3-bucket module requires a bucket for S3 server access logs, and the CMR
# account has none yet -- cmr-infra's foundation layer only creates the state
# backend. Set var.logging_bucket to reuse an existing one instead, and this is
# skipped.
module "logging" {
  source   = "github.com/codeforamerica/tofu-modules-aws-logging?ref=2.2.0"
  for_each = var.logging_bucket == null ? toset(["this"]) : toset([])

  project     = var.project
  environment = var.environment

  # No Datadog forwarder is deployed in this account.
  log_groups_to_datadog = false
}

module "content" {
  source = "github.com/codeforamerica/tofu-modules-aws-s3-bucket?ref=1.1.0"

  name        = var.application
  project     = var.project
  state       = var.state
  environment = var.environment

  force_delete   = var.force_delete
  logging_bucket = local.logging_bucket
  sensitivity    = "public"

  # The module's key policy can't grant CloudFront's service principal, so
  # the key is created in kms.tf instead. See templates/key-policy.yaml.tftpl.
  kms = {
    create = false
    arn    = aws_kms_key.content.arn
  }

  additional_policy_statements = yamldecode(templatefile("${local.template_dir}/bucket-policy.yaml.tftpl", {
    bucket_arn       = "arn:${data.aws_partition.current.partition}:s3:::${local.bucket_name}",
    distribution_arn = aws_cloudfront_distribution.site.arn,
  }))
}

# The site is one file with no build step, so the content is managed here
# rather than pushed by a separate deploy pipeline. Editing the HTML and
# running `tofu apply` republishes it, and terraform_data.invalidation in
# cloudfront.tf clears the CDN cache off this object's etag.
resource "aws_s3_object" "index" {
  bucket       = module.content.name
  key          = "index.html"
  source       = local.content_path
  source_hash  = filemd5(local.content_path)
  content_type = "text/html; charset=utf-8"

  kms_key_id = aws_kms_key.content.arn

  # Short max-age keeps a stale copy from outliving a failed invalidation.
  cache_control = "public, max-age=300"
}