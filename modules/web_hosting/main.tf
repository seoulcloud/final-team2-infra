
resource "aws_s3_bucket_website_configuration" "static_site" {
  bucket = var.bucket_id
  # bucket = var.bucket_name

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_policy" "static_site_policy" {
  bucket = var.bucket_id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AllowCloudFrontServiceAccessOnly",
        Effect = "Allow",
        Principal = {
          Service = "cloudfront.amazonaws.com"
        },
        Action   = "s3:GetObject",
        Resource = "${var.bucket_arn}/*",
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = "arn:aws:cloudfront::194722398200:distribution/E1O23LTYRS9I1"
          }
        }
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.allow_public]
}


resource "aws_s3_bucket_versioning" "static_site_versioning" {
  bucket = var.bucket_id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "allow_public" {
  bucket = var.bucket_id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
