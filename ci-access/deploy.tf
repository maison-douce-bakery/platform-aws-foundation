# CI identity for deploying application services. Same shape as plan and apply: the user can only
# assume the role. The role itself is narrower than ci-apply: it deploys ECS services and nothing else.
resource "aws_iam_user" "ci_deploy" {
  name = "${local.name_prefix}-ci-deploy"
  path = local.platform_path
}

data "aws_iam_policy_document" "ci_deploy_user" {
  statement {
    sid       = "AssumeDeployRoleOnly"
    actions   = ["sts:AssumeRole", "sts:TagSession"]
    resources = [aws_iam_role.ci_deploy.arn]
  }
}

resource "aws_iam_user_policy" "ci_deploy" {
  name   = "assume-deploy-role"
  user   = aws_iam_user.ci_deploy.name
  policy = data.aws_iam_policy_document.ci_deploy_user.json
}

data "aws_iam_policy_document" "ci_deploy_trust" {
  statement {
    actions = ["sts:AssumeRole", "sts:TagSession"]

    principals {
      type        = "AWS"
      identifiers = [aws_iam_user.ci_deploy.arn]
    }
  }
}

resource "aws_iam_role" "ci_deploy" {
  name                 = "${local.name_prefix}-ci-deploy"
  path                 = local.platform_path
  description          = "Role for deploying application ECS services in CI, narrower than ci-apply."
  assume_role_policy   = data.aws_iam_policy_document.ci_deploy_trust.json
  permissions_boundary = data.aws_iam_policy.workload_boundary.arn
  max_session_duration = 3600
}

# Narrow policy: only the actions the `ecs-service` module uses, scoped where resource-level
# permissions exist. The workload boundary still caps everything underneath.
data "aws_iam_policy_document" "ci_deploy" {
  # ECS services and task definitions. Most ECS actions don't take resource-level permissions, so
  # the account is the smallest scope; `aws:RequestedRegion` holds the role to ap-southeast-2.
  statement {
    sid = "EcsDeploy"
    actions = [
      "ecs:RegisterTaskDefinition",
      "ecs:DeregisterTaskDefinition",
      "ecs:Describe*",
      "ecs:List*",
      "ecs:CreateService",
      "ecs:UpdateService",
      "ecs:DeleteService",
      "ecs:UpdateServicePrimaryTaskSet",
      "ecs:TagResource",
      "ecs:UntagResource",
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.region]
    }
  }

  # Task roles the services use. The boundary prevents creating a role without itself.
  statement {
    sid = "WorkloadIamRoles"
    actions = [
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:GetRole",
      "iam:TagRole",
      "iam:UntagRole",
      "iam:UpdateAssumeRolePolicy",
      "iam:PutRolePolicy",
      "iam:DeleteRolePolicy",
      "iam:GetRolePolicy",
      "iam:ListRolePolicies",
      "iam:AttachRolePolicy",
      "iam:DetachRolePolicy",
      "iam:ListAttachedRolePolicies",
      "iam:PutRolePermissionsBoundary",
    ]
    resources = ["arn:aws:iam::${local.account_id}:role/workload/*"]
  }

  # Passing the task's execution and application roles to ECS when it starts the task.
  statement {
    sid       = "PassWorkloadRolesToEcs"
    actions   = ["iam:PassRole"]
    resources = ["arn:aws:iam::${local.account_id}:role/workload/*"]
    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["ecs-tasks.amazonaws.com"]
    }
  }

  # Container logs.
  statement {
    sid = "ContainerLogs"
    actions = [
      "logs:CreateLogGroup",
      "logs:DeleteLogGroup",
      "logs:DescribeLogGroups",
      "logs:ListTagsForResource",
      "logs:TagResource",
      "logs:UntagResource",
      "logs:PutRetentionPolicy",
      "logs:DeleteRetentionPolicy",
    ]
    resources = ["arn:aws:logs:${var.region}:${local.account_id}:log-group:/ecs/*"]
  }

  # Task security groups and ingress/egress rules. EC2 rarely supports resource-level permissions,
  # so the scope is the region; the module creates named resources in the dev VPC only.
  statement {
    sid = "TaskNetworking"
    actions = [
      "ec2:CreateSecurityGroup",
      "ec2:DeleteSecurityGroup",
      "ec2:AuthorizeSecurityGroup*",
      "ec2:RevokeSecurityGroup*",
      "ec2:ModifySecurityGroupRules",
      "ec2:UpdateSecurityGroupRule*",
      "ec2:CreateTags",
      "ec2:DeleteTags",
      "ec2:Describe*",
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.region]
    }
  }

  # Looking up secrets and keys by name. No GetSecretValue: deployments reference secrets, not read them.
  statement {
    sid = "LookupSecretsAndKeys"
    actions = [
      "secretsmanager:DescribeSecret",
      "secretsmanager:ListSecrets",
      "kms:DescribeKey",
      "kms:ListAliases",
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.region]
    }
  }

  statement {
    sid       = "WhoAmI"
    actions   = ["sts:GetCallerIdentity"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "ci_deploy" {
  name   = "deploy-services"
  role   = aws_iam_role.ci_deploy.id
  policy = data.aws_iam_policy_document.ci_deploy.json
}
