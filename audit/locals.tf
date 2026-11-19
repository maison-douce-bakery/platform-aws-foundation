data "aws_caller_identity" "current" {}

locals {
  name_prefix = "mdb-shared"
  account_id  = data.aws_caller_identity.current.account_id

  # Required suffix for S3 account-regional namespace: <account>-<region>-an
  s3_suffix = "${local.account_id}-${var.region}-an"

  trail_name = "${local.name_prefix}-audit"
  # Built as a string: the key and bucket policies need it before the trail exists.
  trail_arn = "arn:aws:cloudtrail:${var.region}:${local.account_id}:trail/${local.trail_name}"

  log_bucket_name  = "${local.name_prefix}-cloudtrail-${local.s3_suffix}"
  state_bucket_arn = "arn:aws:s3:::${local.name_prefix}-tfstate-${local.s3_suffix}"
}
