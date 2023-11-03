output "s3siteurl" {
  value = aws_s3_bucket_website_configuration.bucket.website_endpoint
}

output "cf-default-domainname" {
  value = aws_cloudfront_distribution.distro.domain_name
}

output "cf-alt-domainname" {
  value = aws_cloudfront_distribution.distro.aliases
}

output "bucketpolicy" {
  value = data.aws_iam_policy_document.s3publicaccess.json
}