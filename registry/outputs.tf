output "repository_urls" {
  description = "Image repositories, by name. CI pushes to these and task definitions pull by digest."
  value       = { for name, repo in aws_ecr_repository.this : name => repo.repository_url }
}
