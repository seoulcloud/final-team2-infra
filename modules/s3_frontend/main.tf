

resource "aws_s3_bucket" "frontend" {
  bucket = "${var.prefix}-${var.bucket_name}"


  tags = {
    Environment = var.prefix
    Name        = "${var.prefix}-frontend-bucket"
  }
}

# resource "aws_s3_bucket_policy" "frontend_policy" {
#   bucket = aws_s3_bucket.frontend.id

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Principal = {
#           Service = "cloudfront.amazonaws.com"
#         }
#         Action = "s3:GetObject"
#         Resource = "${aws_s3_bucket.frontend.arn}/*"
#         Condition = {
#           StringEquals = {
#             "AWS:SourceArn" = var.cloudfront_distribution_arn
#           }
#         }
#       }
#     ]
#   })
#   depends_on = [aws_s3_bucket_public_access_block.allow_public]
# }

resource "aws_s3_bucket_public_access_block" "allow_public" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}