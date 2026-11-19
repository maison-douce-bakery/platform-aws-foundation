# Customer managed key for Terraform state encryption.
resource "aws_kms_key" "tfstate" {
  description             = "Encrypts Terraform state in ${local.state_bucket_name}"
  enable_key_rotation     = true
  deletion_window_in_days = 30

  # Losing this key makes every state file unreadable.
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_kms_alias" "tfstate" {
  name          = "alias/${local.name_prefix}-tfstate"
  target_key_id = aws_kms_key.tfstate.key_id
}
