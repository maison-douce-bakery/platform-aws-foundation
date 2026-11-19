# CIS-aligned. No forced rotation, per NIST SP 800-63B.
# Note: the AWS-managed SCP denies iam:*LoginProfile*, so no IAM user here can have
# a console password today. This policy is kept as a compliance baseline.
resource "aws_iam_account_password_policy" "this" {
  minimum_password_length        = 14
  require_uppercase_characters   = true
  require_lowercase_characters   = true
  require_numbers                = true
  require_symbols                = true
  allow_users_to_change_password = true
  password_reuse_prevention      = 24
}
