# 1. bucket_name
# 2. bucket_arn
# 3. website_endpoint (정적 웹 호스팅 설정 시)

output "bucket_name" {
  value = aws_s3_bucket.frontend.bucket
}

output "bucket_domain_name" {
  value = aws_s3_bucket.frontend.bucket_regional_domain_name
}