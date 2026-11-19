output "state_bucket_name" {
  description = "S3 bucket that stores Terraform state for all stacks."
  value       = aws_s3_bucket.tfstate.bucket
}

output "state_kms_key_arn" {
  description = "KMS key that encrypts Terraform state."
  value       = aws_kms_key.tfstate.arn
}
