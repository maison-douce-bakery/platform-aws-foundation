# Backend blocks can't use variables, so these values are literal.
# Bucket and KMS key are created by bootstrap/.
terraform {
  backend "s3" {
    bucket       = "mdb-shared-tfstate-452258152479-ap-southeast-2-an"
    key          = "platform-aws-foundation/iam-baseline/terraform.tfstate"
    region       = "ap-southeast-2"
    encrypt      = true
    kms_key_id   = "arn:aws:kms:ap-southeast-2:452258152479:key/ecb785de-52dc-491e-aedf-7933d87850c3"
    use_lockfile = true
  }
}
