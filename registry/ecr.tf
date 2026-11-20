resource "aws_ecr_repository" "this" {
  for_each = toset(local.repositories)

  name = each.value

  # A tag already pushed can never be moved, so a digest keeps meaning what it meant.
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  # Images are built from public base images and public source, so the AWS-managed key is enough.
  # A customer managed key would add about $1 a month for no secret to protect.
  encryption_configuration {
    encryption_type = "AES256"
  }
}

resource "aws_ecr_lifecycle_policy" "this" {
  for_each = aws_ecr_repository.this

  repository = each.value.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Delete untagged images after a day: a failed or replaced build leaves them behind."
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 1
        }
        action = { type = "expire" }
      },
      {
        rulePriority = 2
        description  = "Keep the most recent images only."
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = local.kept_images
        }
        action = { type = "expire" }
      },
    ]
  })
}
