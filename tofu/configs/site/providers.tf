# CloudFront and its ACM certificates are global resources that must live in
# us-east-1, and the bucket is colocated so there is only ever one provider.
provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      application = local.prefix
      environment = var.environment
      program     = var.program
      project     = var.project
    }
  }
}