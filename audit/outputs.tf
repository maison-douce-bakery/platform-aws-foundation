output "trail_arn" {
  description = "CloudTrail trail that records all account activity."
  value       = aws_cloudtrail.audit.arn
}

output "log_bucket_name" {
  description = "S3 bucket that stores CloudTrail logs."
  value       = aws_s3_bucket.cloudtrail.bucket
}

output "audit_kms_key_arn" {
  description = "KMS key that encrypts CloudTrail logs."
  value       = aws_kms_key.audit.arn
}
