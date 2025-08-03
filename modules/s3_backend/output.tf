# 1. bucket_name
# 2. bucket_arn

output "bucket_name" {
  value = aws_s3_bucket.backend.bucket
}