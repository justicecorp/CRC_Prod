# returns the region this provider is configured for
data "aws_region" "current" {}

data "aws_iam_policy_document" "s3publicaccess" {
  statement {
    sid    = "PublicReadGetObject"
    effect = "Allow"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.bucket.arn}/*"]
    condition {
      test     = "StringLike"
      variable = "aws:Referer"
      values   = ["${random_password.refererstring.result}"]
    }

  }

}

data "aws_route53_zone" "zone" {
  name         = var.HostedZone
  private_zone = false
}