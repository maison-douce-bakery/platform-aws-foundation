# CI identity for terraform plan. The user can do one thing: assume the plan role.
resource "aws_iam_user" "ci_plan" {
  name = "${local.name_prefix}-ci-plan"
  path = local.platform_path
}

data "aws_iam_policy_document" "ci_plan_user" {
  statement {
    sid       = "AssumePlanRoleOnly"
    actions   = ["sts:AssumeRole", "sts:TagSession"]
    resources = [aws_iam_role.ci_plan.arn]
  }
}

resource "aws_iam_user_policy" "ci_plan" {
  name   = "assume-plan-role"
  user   = aws_iam_user.ci_plan.name
  policy = data.aws_iam_policy_document.ci_plan_user.json
}

data "aws_iam_policy_document" "ci_plan_trust" {
  statement {
    actions = ["sts:AssumeRole", "sts:TagSession"]

    principals {
      type        = "AWS"
      identifiers = [aws_iam_user.ci_plan.arn]
    }
  }
}

resource "aws_iam_role" "ci_plan" {
  name                 = "${local.name_prefix}-ci-plan"
  path                 = local.platform_path
  description          = "Read-only role for terraform plan in CI."
  assume_role_policy   = data.aws_iam_policy_document.ci_plan_trust.json
  permissions_boundary = data.aws_iam_policy.workload_boundary.arn
  max_session_duration = 3600
}

resource "aws_iam_role_policy_attachment" "ci_plan_readonly" {
  role       = aws_iam_role.ci_plan.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# ReadOnlyAccess can read state. Plan also writes and deletes the lock file.
data "aws_iam_policy_document" "ci_plan_state_lock" {
  statement {
    sid       = "StateLockFile"
    actions   = ["s3:PutObject", "s3:DeleteObject"]
    resources = ["${local.state_bucket_arn}/*.tflock"]
  }

  statement {
    sid       = "StateKey"
    actions   = ["kms:Decrypt", "kms:GenerateDataKey"]
    resources = [data.aws_kms_alias.tfstate.target_key_arn]
  }
}

resource "aws_iam_role_policy" "ci_plan_state_lock" {
  name   = "terraform-state-lock"
  role   = aws_iam_role.ci_plan.name
  policy = data.aws_iam_policy_document.ci_plan_state_lock.json
}
