provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project     = "mdb"
      Environment = "shared"
      ManagedBy   = "terraform"
      Repo        = "platform-aws-foundation"
    }
  }
}