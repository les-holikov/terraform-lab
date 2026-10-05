terraform {
    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = "~> 5.0"
        }
    }
}

provider "aws" {
    region = var.region
    profile = var.profile
}

resource "aws_s3_bucket" "db" {
  bucket_prefix = "${var.project_name}-"
  force_destroy = true
}

resource "aws_dynamodb_table" "uploads" {
  name = "${var.project_name}-uploads"
  billing_mode = "PAY_PER_REQUEST"
  hash_key = "id"

  attribute {
    name = "id"
    type = "S"
  }
}

resource "aws_iam_user" "app" {
  name = "${var.project_name}-app"
}

resource "aws_iam_access_key" "app" {
  user = aws_iam_user.app.name
}

resource "aws_iam_user_policy" "app" {
  name = "${var.project_name}-app-policy"
  user = aws_iam_user.app.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
        {
            Effect = "Allow"
            Action = ["s3:PutObject", "s3:GetObject", "s3:ListBucket"]
            Resource = [
                aws_s3_bucket.db.arn, 
                "${aws_s3_bucket.db.arn}/*"
            ]
        },
        {
            Effect = "Allow"
            Action = ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:Scan"]
            Resource = [aws_dynamodb_table.uploads.arn]
        },
    ]
  })
}

resource "local_file" "env" {
  filename = "${path.module}/flaks_app/.env"
  content =<<-EOT
    BUCKET_NAME=${aws_s3_bucket.db.bucket}
    DYNAMODB_TABLE=${aws_dynamodb_table.uploads.name}
    AWS_ACCESS_KEY_ID=${aws_iam_access_key.app.id}
    AWS_SECRET_ACCESS_KEY=${aws_iam_access_key.app.secret}
    AWS_REGION=${var.region}
  EOT
}