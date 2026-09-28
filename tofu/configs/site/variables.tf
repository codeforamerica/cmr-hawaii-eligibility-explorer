variable "application" {
  type        = string
  description = "Name of the application, used in resource naming and tagging."
  default     = "eligibility-explorer"
}

variable "content_file" {
  type        = string
  description = <<-EOT
    Path to the single HTML file published as the site's index. Relative paths
    are resolved from this configuration directory.
    EOT
  default     = "../../../hi_eligibility_explorer.html"
}

variable "create_hosted_zone" {
  type        = bool
  description = <<-EOT
    Create the Route 53 hosted zone for `domain` in this account rather than
    looking up an existing one. Defaults to true because the parent
    `dev.codeforamerica.app` zone is created by shared-services-infra in an
    account this configuration does not run in, so the only way to manage
    records from the CMR account is a delegated subdomain.
    The parent zone's owner adds the NS records from the
    `hosted_zone_name_servers` output. See "DNS" in the README.
    EOT
  default     = true
}

variable "domain" {
  type        = string
  description = <<-EOT
    Route 53 hosted zone the site's record is created in. With
    `create_hosted_zone`, this is the delegated zone created here and the site
    is served from its apex. Point it at an existing zone and set
    `create_hosted_zone` to false to use one this account already owns.
    EOT
  default     = "hi-eligibility-explorer.dev.codeforamerica.app"
}

variable "enable_waf" {
  type        = bool
  description = <<-EOT
    Put an AWS WAF web ACL in front of the distribution. Adds roughly $10/month
    in fixed WebACL and managed rule group charges before per-request costs.
    EOT
  default     = true
}

variable "environment" {
  type        = string
  description = <<-EOT
    Deployment environment, used in resource names and tags. This project runs
    a single environment; changing this renames the bucket and KMS alias, which
    replaces them.
    EOT
  default     = "development"
}

variable "force_delete" {
  type        = bool
  description = <<-EOT
    Allow the content bucket to be destroyed while it still holds objects.
    Should be `false` in production.
    EOT
  default     = false
}

variable "logging_bucket" {
  type        = string
  description = <<-EOT
    S3 bucket to write CloudFront access logs to. Logging is disabled when this
    is null. The bucket must have ACLs enabled and grant CloudFront write
    access, which is why this is not created here.
    EOT
  default     = null
}

variable "program" {
  type        = string
  description = "Name of the program this project belongs to."
  default     = "cmr"
}

variable "project" {
  type        = string
  description = "Name of the project."
  default     = "clear-my-record"
}

variable "state" {
  type        = string
  description = <<-EOT
    Two-letter code for the state this deployment serves, used in resource
    names. Null for deployments that are not state-specific.
    EOT
  default     = "hi"
}

variable "subdomain" {
  type        = string
  description = <<-EOT
    Subdomain the site is served from, prepended to `domain`. Null by default,
    so the site is served from the apex of `domain` -- which is what you want
    when `domain` is a zone delegated specifically to this site. Set it when
    pointing at a broader zone this account already owns.
    EOT
  default     = null
}

variable "waf_rate_limit" {
  type        = number
  description = <<-EOT
    Requests per five minutes from a single IP before the WAF blocks it. Only
    used when `enable_waf` is true.
    EOT
  default     = 2000
}