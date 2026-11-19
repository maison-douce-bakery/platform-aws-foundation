data "aws_caller_identity" "current" {}

locals {
  name_prefix = "mdb-shared"

  # Required suffix for S3 account-regional namespace: <account>-<region>-an
  s3_suffix = "${data.aws_caller_identity.current.account_id}-${var.region}-an"

  state_bucket_name = "${local.name_prefix}-tfstate-${local.s3_suffix}"
}
