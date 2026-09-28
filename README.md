# Hawaii Clean Slate Eligibility Explorer

A single self-contained HTML page exploring Clean Slate record-clearing
eligibility. `hi_eligibility_explorer.html` is the whole application.

## Infrastructure

`tofu/configs/site` publishes the page to a public HTTPS URL. It runs in the
CMR AWS account and stores state in the backend `cmr-infra`'s foundation layer
created there.

There is one environment for this application: `development`.

| Resource | Purpose |
| --- | --- |
| S3 bucket | Holds `index.html`. Private; reachable only through CloudFront. Built with [`tofu-modules-aws-s3-bucket`][s3-module]. |
| KMS key | Encrypts the bucket. Created here rather than by the s3 module — see [Why the KMS key is local](#why-the-kms-key-is-local). |
| Logging bucket | S3 server access logs, required by the s3 module. Built with [`tofu-modules-aws-logging`][logging-module]. Set `logging_bucket` to reuse an existing one instead. |
| CloudFront distribution | TLS, caching, and the public hostname. Reads S3 through an Origin Access Control identity. |
| Response headers policy | HSTS, CSP, `X-Content-Type-Options`, `X-Frame-Options`, referrer policy. |
| ACM certificate | Public certificate for the hostname, DNS-validated. |
| Route 53 zone and records | The delegated zone plus its apex A/AAAA alias records. |
| WAF web ACL | Rate limiting plus the AWS managed IP-reputation, common, and known-bad-inputs rule groups. Disable with `enable_waf = false`. |

The page content is managed by OpenTofu as an `aws_s3_object`, so there is no
separate deploy pipeline. Edit the HTML, apply, and a CloudFront invalidation
runs automatically.

### Prerequisite: DNS delegation

The `dev.codeforamerica.app` zone is created by [`shared-services-infra`][shared-services]
in an account this configuration does not run in, so records can't be written
there from the CMR account. Instead this config creates its own hosted zone for
`hi-eligibility-explorer.dev.codeforamerica.app` and serves the site from that
zone's apex.

That means the first apply happens in two passes:

1. Run `tofu apply`. Creating the zone, bucket, and WAF succeeds. The ACM validation step
   is blocked because the delegating NS record does not exist yet.
2. Take the `hosted_zone_name_servers` output to `#devops` and ask them to add
   the matching NS record to `dev.codeforamerica.app` in shared-services.
3. Apply again. Certificate validation completes and the distribution comes up.

To skip delegation entirely, point `domain` at a zone this account already owns
and set `create_hosted_zone = false`.

### Deploying

Requires OpenTofu 1.11+, the AWS CLI, and an SSO session for the CMR account.

```sh
cd tofu/configs/site
tofu init
tofu plan
tofu apply
```

[logging-module]: https://github.com/codeforamerica/tofu-modules-aws-logging
[s3-module]: https://github.com/codeforamerica/tofu-modules-aws-s3-bucket
[shared-services]: https://github.com/codeforamerica/shared-services-infra