# Block public access for every S3 bucket in the account, including future ones.
resource "aws_s3_account_public_access_block" "this" {
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# The settings below are regional and apply to var.region only.

# Encrypt every new EBS volume with the default aws/ebs key.
resource "aws_ebs_encryption_by_default" "this" {
  enabled = true
}

# Block public sharing of EBS snapshots.
resource "aws_ebs_snapshot_block_public_access" "this" {
  state = "block-all-sharing"
}

# Block public sharing of AMIs.
resource "aws_ec2_image_block_public_access" "this" {
  state = "block-new-sharing"
}

# Require IMDSv2 on new EC2 instances. Hop limit 2 lets containers on the host reach IMDS.
resource "aws_ec2_instance_metadata_defaults" "this" {
  http_tokens                 = "required"
  http_put_response_hop_limit = 2
}
