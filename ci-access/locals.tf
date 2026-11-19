data "aws_caller_identity" "current" {}

# Created by iam-baseline. Looked up by name to avoid depending on its state.
data "aws_iam_policy" "workload_boundary" {
  name        = "mdb-shared-workload-boundary"
  path_prefix = "/platform/"
}

data "aws_kms_alias" "tfstate" {
  name = "alias/mdb-shared-tfstate"
}

locals {
  name_prefix = "mdb-shared"
  account_id  = data.aws_caller_identity.current.account_id

  # Platform IAM lives here. The boundary blocks workloads from changing it.
  platform_path = "/platform/"

  state_bucket_arn = "arn:aws:s3:::${local.name_prefix}-tfstate-${local.account_id}-${var.region}-an"
}
