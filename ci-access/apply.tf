# CI identity for terraform apply. The user can do one thing: assume the apply role.
resource "aws_iam_user" "ci_apply" {
  name = "${local.name_prefix}-ci-apply"
  path = local.platform_path
}

data "aws_iam_policy_document" "ci_apply_user" {
  statement {
    sid       = "AssumeApplyRoleOnly"
    actions   = ["sts:AssumeRole", "sts:TagSession"]
    resources = [aws_iam_role.ci_apply.arn]
  }
}

resource "aws_iam_user_policy" "ci_apply" {
  name   = "assume-apply-role"
  user   = aws_iam_user.ci_apply.name
  policy = data.aws_iam_policy_document.ci_apply_user.json
}

data "aws_iam_policy_document" "ci_apply_trust" {
  statement {
    actions = ["sts:AssumeRole", "sts:TagSession"]

    principals {
      type        = "AWS"
      identifiers = [aws_iam_user.ci_apply.arn]
    }
  }
}

# Broad on purpose. The permission boundary is what keeps this role safe.
resource "aws_iam_role" "ci_apply" {
  name                 = "${local.name_prefix}-ci-apply"
  path                 = local.platform_path
  description          = "Role for terraform apply in CI, capped by the workload boundary."
  assume_role_policy   = data.aws_iam_policy_document.ci_apply_trust.json
  permissions_boundary = data.aws_iam_policy.workload_boundary.arn
  max_session_duration = 3600
}

resource "aws_iam_role_policy_attachment" "ci_apply_admin" {
  role       = aws_iam_role.ci_apply.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
