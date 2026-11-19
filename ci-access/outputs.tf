output "ci_plan_user_name" {
  description = "IAM user whose access key goes into GitHub for plan jobs."
  value       = aws_iam_user.ci_plan.name
}

output "ci_plan_role_arn" {
  description = "Role that plan jobs assume."
  value       = aws_iam_role.ci_plan.arn
}

output "ci_apply_user_name" {
  description = "IAM user whose access key goes into GitHub for apply jobs."
  value       = aws_iam_user.ci_apply.name
}

output "ci_apply_role_arn" {
  description = "Role that apply jobs assume."
  value       = aws_iam_role.ci_apply.arn
}
