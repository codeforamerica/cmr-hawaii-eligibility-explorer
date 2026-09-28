data "aws_caller_identity" "identity" {}

data "aws_partition" "current" {}

data "aws_route53_zone" "domain" {
  for_each = var.create_hosted_zone ? toset([]) : toset(["this"])

  name = var.domain
}