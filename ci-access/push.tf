# CI identity for pushing container images. The user can do one thing: assume the push role.
resource "aws_iam_user" "ci_push" {
  name = "${local.name_prefix}-ci-push"
  path = local.platform_path
}

data "aws_iam_policy_document" "ci_push_user" {
  statement {
    sid       = "AssumePushRoleOnly"
    actions   = ["sts:AssumeRole", "sts:TagSession"]
    resources = [aws_iam_role.ci_push.arn]
  }
}

resource "aws_iam_user_policy" "ci_push" {
  name   = "assume-push-role"
  user   = aws_iam_user.ci_push.name
  policy = data.aws_iam_policy_document.ci_push_user.json
}

data "aws_iam_policy_document" "ci_push_trust" {
  statement {
    actions = ["sts:AssumeRole", "sts:TagSession"]

    principals {
      type        = "AWS"
      identifiers = [aws_iam_user.ci_push.arn]
    }
  }
}

resource "aws_iam_role" "ci_push" {
  name                 = "${local.name_prefix}-ci-push"
  path                 = local.platform_path
  description          = "Role for pushing images to the mdb/ ECR repositories in CI."
  assume_role_policy   = data.aws_iam_policy_document.ci_push_trust.json
  permissions_boundary = data.aws_iam_policy.workload_boundary.arn
  max_session_duration = 3600
}

# The repository ARN pattern avoids reading the registry stack's state. No delete actions:
# a build may add images, never remove them, and the lifecycle policy does the cleaning up.
data "aws_iam_policy_document" "ci_push" {
  statement {
    sid     = "LoginToRegistry"
    actions = ["ecr:GetAuthorizationToken"]
    # The only ECR action without resource-level permissions.
    resources = ["*"]
  }

  statement {
    sid = "PushToPlatformRepositories"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:PutImage",
      "ecr:BatchGetImage",
      "ecr:DescribeImages",
    ]
    resources = ["arn:aws:ecr:${var.region}:${local.account_id}:repository/mdb/*"]
  }
}

resource "aws_iam_role_policy" "ci_push" {
  name   = "push-images"
  role   = aws_iam_role.ci_push.id
  policy = data.aws_iam_policy_document.ci_push.json
}
