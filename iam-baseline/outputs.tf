output "workload_boundary_arn" {
  description = "Permission boundary that CI roles and the roles they create must carry."
  value       = aws_iam_policy.workload_boundary.arn
}
