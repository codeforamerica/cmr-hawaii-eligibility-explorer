resource "aws_kms_key" "content" {
  description         = "Encryption key for the ${var.application} content bucket."
  enable_key_rotation = true
}

resource "aws_kms_alias" "content" {
  name          = "alias/${local.bucket_name}"
  target_key_id = aws_kms_key.content.id
}

resource "aws_kms_key_policy" "content" {
  key_id = aws_kms_key.content.id

  policy = jsonencode(yamldecode(templatefile("${local.template_dir}/key-policy.yaml.tftpl", {
    account          = data.aws_caller_identity.identity.account_id,
    bucket           = local.bucket_name,
    distribution_arn = aws_cloudfront_distribution.site.arn,
    partition        = data.aws_partition.current.partition,
  })))
}