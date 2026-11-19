data "aws_caller_identity" "current" {}

# Look up the state KMS key by alias, so this stack doesn't depend on bootstrap's state.
data "aws_kms_alias" "tfstate" {
  name = "alias/mdb-shared-tfstate"
}

data "aws_kms_alias" "audit" {
  name = "alias/mdb-shared-audit"
}

locals {
  name_prefix = "mdb-shared"
  account_id  = data.aws_caller_identity.current.account_id

  # IAM resources owned by platform-aws-foundation live under this path.
  platform_path = "/platform/"

  boundary_name = "${local.name_prefix}-workload-boundary"
  # Built as a string because the policy must reference its own ARN.
  boundary_arn = "arn:aws:iam::${local.account_id}:policy${local.platform_path}${local.boundary_name}"

  state_bucket_arn = "arn:aws:s3:::${local.name_prefix}-tfstate-${local.account_id}-${var.region}-an"

  # Created by audit/.
  log_bucket_arn = "arn:aws:s3:::${local.name_prefix}-cloudtrail-${local.account_id}-${var.region}-an"
  trail_arn      = "arn:aws:cloudtrail:${var.region}:${local.account_id}:trail/${local.name_prefix}-audit"
}
