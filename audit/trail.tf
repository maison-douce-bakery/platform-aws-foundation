resource "aws_cloudtrail" "audit" {
  name                          = local.trail_name
  s3_bucket_name                = aws_s3_bucket.cloudtrail.id
  kms_key_id                    = aws_kms_key.audit.arn
  is_multi_region_trail         = true
  include_global_service_events = true
  enable_log_file_validation    = true

  advanced_event_selector {
    name = "All management events"

    field_selector {
      field  = "eventCategory"
      equals = ["Management"]
    }
  }

  # Who read or wrote Terraform state. Limited to one bucket to keep cost near zero.
  advanced_event_selector {
    name = "Terraform state access"

    field_selector {
      field  = "eventCategory"
      equals = ["Data"]
    }

    field_selector {
      field  = "resources.type"
      equals = ["AWS::S3::Object"]
    }

    field_selector {
      field       = "resources.ARN"
      starts_with = ["${local.state_bucket_arn}/"]
    }
  }

  lifecycle {
    prevent_destroy = true
  }

  # The trail validates bucket and key access on create.
  depends_on = [aws_s3_bucket_policy.cloudtrail]
}
