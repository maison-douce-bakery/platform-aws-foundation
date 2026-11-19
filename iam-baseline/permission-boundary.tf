# Ceiling for every CI role and every role those roles create.
# It grants nothing on its own. Effective access = identity policy ∩ this boundary.
data "aws_iam_policy_document" "workload_boundary" {
  # Start from everything, then carve out with explicit denies.
  statement {
    sid       = "AllowAllUnlessDenied"
    effect    = "Allow"
    actions   = ["*"]
    resources = ["*"]
  }

  # New roles must carry this same boundary, so it propagates and can't be escaped.
  statement {
    sid       = "DenyRoleWithoutBoundary"
    effect    = "Deny"
    actions   = ["iam:CreateRole", "iam:PutRolePermissionsBoundary"]
    resources = ["*"]

    condition {
      test     = "StringNotEquals"
      variable = "iam:PermissionsBoundary"
      values   = [local.boundary_arn]
    }
  }

  statement {
    sid       = "DenyBoundaryRemoval"
    effect    = "Deny"
    actions   = ["iam:DeleteRolePermissionsBoundary"]
    resources = ["*"]
  }

  # Platform IAM (CI users, CI roles, this boundary) is read-only for workloads.
  statement {
    sid         = "DenyPlatformIamChanges"
    effect      = "Deny"
    not_actions = ["iam:Get*", "iam:List*", "iam:Simulate*"]
    resources = [
      "arn:aws:iam::${local.account_id}:role${local.platform_path}*",
      "arn:aws:iam::${local.account_id}:user${local.platform_path}*",
      "arn:aws:iam::${local.account_id}:policy${local.platform_path}*",
      "arn:aws:iam::${local.account_id}:instance-profile${local.platform_path}*",
    ]
  }

  # Workloads use roles. Only admins create IAM users and keys.
  statement {
    sid       = "DenyIamUsersAndKeys"
    effect    = "Deny"
    actions   = ["iam:CreateUser", "iam:CreateAccessKey"]
    resources = ["*"]
  }

  # Bucket settings of the state and audit log buckets can't be changed.
  statement {
    sid    = "DenyProtectedBucketChanges"
    effect = "Deny"
    actions = [
      "s3:DeleteBucket",
      "s3:DeleteBucketPolicy",
      "s3:PutBucketPolicy",
      "s3:PutBucketVersioning",
      "s3:PutBucketObjectLockConfiguration",
      "s3:PutEncryptionConfiguration",
      "s3:PutLifecycleConfiguration",
      "s3:PutBucketPublicAccessBlock",
      "s3:PutBucketOwnershipControls",
      "s3:PutReplicationConfiguration",
    ]
    resources = [local.state_bucket_arn, local.log_bucket_arn]
  }

  # State objects stay readable and writable. Their history is protected.
  statement {
    sid       = "DenyStateHistoryDeletion"
    effect    = "Deny"
    actions   = ["s3:DeleteObjectVersion"]
    resources = ["${local.state_bucket_arn}/*"]
  }

  # Only CloudTrail writes audit logs. Nothing may hide, rewrite or unlock them.
  statement {
    sid    = "DenyAuditLogTampering"
    effect = "Deny"
    actions = [
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:DeleteObjectVersion",
      "s3:PutObjectRetention",
      "s3:PutObjectLegalHold",
      "s3:BypassGovernanceRetention",
    ]
    resources = ["${local.log_bucket_arn}/*"]
  }

  statement {
    sid    = "DenyProtectedKeyChanges"
    effect = "Deny"
    actions = [
      "kms:ScheduleKeyDeletion",
      "kms:DisableKey",
      "kms:DisableKeyRotation",
      "kms:PutKeyPolicy",
      "kms:DeleteAlias",
      "kms:UpdateAlias",
    ]
    resources = [
      data.aws_kms_alias.tfstate.target_key_arn,
      data.aws_kms_alias.tfstate.arn,
      data.aws_kms_alias.audit.target_key_arn,
      data.aws_kms_alias.audit.arn,
    ]
  }

  statement {
    sid    = "DenyAuditTrailChanges"
    effect = "Deny"
    actions = [
      "cloudtrail:StopLogging",
      "cloudtrail:DeleteTrail",
      "cloudtrail:UpdateTrail",
      "cloudtrail:PutEventSelectors",
      "cloudtrail:PutInsightSelectors",
    ]
    resources = [local.trail_arn]
  }

  statement {
    sid    = "DenyCostMonitorChanges"
    effect = "Deny"
    actions = [
      "ce:DeleteAnomalyMonitor",
      "ce:UpdateAnomalyMonitor",
      "ce:DeleteAnomalySubscription",
      "ce:UpdateAnomalySubscription",
    ]
    resources = ["*"]
  }

  # Account guardrails from account-baseline and iam-baseline.
  statement {
    sid    = "DenyGuardrailChanges"
    effect = "Deny"
    actions = [
      "s3:PutAccountPublicAccessBlock",
      "ec2:DisableEbsEncryptionByDefault",
      "ec2:ModifyEbsDefaultKmsKeyId",
      "ec2:ResetEbsDefaultKmsKeyId",
      "ec2:EnableSnapshotBlockPublicAccess",
      "ec2:DisableSnapshotBlockPublicAccess",
      "ec2:EnableImageBlockPublicAccess",
      "ec2:DisableImageBlockPublicAccess",
      "ec2:ModifyInstanceMetadataDefaults",
      "iam:UpdateAccountPasswordPolicy",
      "iam:DeleteAccountPasswordPolicy",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "DenyBudgetChanges"
    effect = "Deny"
    actions = [
      "budgets:ModifyBudget",
      "budgets:CreateBudgetAction",
      "budgets:UpdateBudgetAction",
      "budgets:DeleteBudgetAction",
      "budgets:ExecuteBudgetAction",
    ]
    resources = ["arn:aws:budgets::${local.account_id}:budget/${local.name_prefix}-*"]
  }
}

resource "aws_iam_policy" "workload_boundary" {
  name        = local.boundary_name
  path        = local.platform_path
  description = "Permission boundary for CI roles and every role they create."
  policy      = data.aws_iam_policy_document.workload_boundary.json
}
