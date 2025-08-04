

resource "aws_s3_bucket" "backend" {
  bucket = "${var.prefix}-${var.bucket_name}"

  tags = {
    Environment = var.prefix
    Name        = "${var.prefix}-backend-bucket"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "backend_lifecycle" {
  bucket = aws_s3_bucket.backend.id

  rule {
    id     = "expire-logs"
    status = "Enabled"

    expiration {
      days = 30
    }

    filter {
      prefix = "" # 전체 버킷에 적용
    }
  }
}

