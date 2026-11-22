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

output "ci_push_user_name" {
  description = "IAM user whose access key goes into GitHub for image push jobs."
  value       = aws_iam_user.ci_push.name
}

output "ci_push_role_arn" {
  description = "Role that image push jobs assume."
  value       = aws_iam_role.ci_push.arn
}

output "ci_deploy_user_name" {
  description = "IAM user whose access key goes into GitHub for application deployment jobs."
  value       = aws_iam_user.ci_deploy.name
}

output "ci_deploy_role_arn" {
  description = "Role that application deployment jobs assume."
  value       = aws_iam_role.ci_deploy.arn
}
