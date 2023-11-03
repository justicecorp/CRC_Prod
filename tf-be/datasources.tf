# Since our provider is AWS, there are specific data sources we can use 
### aws_ami is a DATA SOURCE (https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami)
## There are MANYYYY AWS data sources
## aws_ami is specifically for fetching AMI IDs dynamically
data "aws_ami" "app_ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name = "name"
    #values = ["al2023-ami-2023*"]
    values = ["al2023-ami-2023.1.20230912.0-kernel-6.1-x86_64"]
  }
}

# This runs every time Plan is run. IT WILL ALWAYS OVERWRITE THE EXISTING ZIP FILE
# This Data Source generates an archive (type choosable) from a given path to a specified path
data "archive_file" "lambdaZip" {
  type        = "zip"
  output_path = "${path.module}/../web-be/lambda.zip"
  source_dir  = "${path.module}/../web-be/lambda/"
}

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