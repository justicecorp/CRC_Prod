terraform {
  # specifies the required provider for this terraform module
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = ">= 5.21.0"
      configuration_aliases = [aws.east1]
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.0"
    }
  }
}

locals {
  resumehtmlname           = "resume_${var.WebCodeVersion}.html"
  homehtmlname             = "home_${var.WebCodeVersion}.html"
  bloghtmlname             = "blog_${var.WebCodeVersion}.html"
  errorhtmlname             = "error_${var.WebCodeVersion}.html"
  projectshtmlname          = "projects_${var.WebCodeVersion}.html"
  contacthtmlname          = "contact_${var.WebCodeVersion}.html"
  jsname                   = "index_${var.WebCodeVersion}.js"
  cforiginid               = "myS3staticOrigin"
  cachingoptimizedpolicyid = "658327ea-f89d-4fab-a63d-7e88639e58f6"
  cachingdisabledpolicyid  = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
  htmlmap = {
    "blog.html" = local.bloghtmlname
    "resume.html" = local.resumehtmlname
    "home.html" = local.homehtmlname
    "projects.html" = local.projectshtmlname
    "contact.html" = local.contacthtmlname
  }
  templatefilemap = {
    JAVASCRIPTPATH = local.jsname
    BLOGPATH = local.bloghtmlname 
    RESUMEPATH = local.resumehtmlname 
    HOMEPATH = local.homehtmlname
    PROJECTSPATH = local.projectshtmlname
    CONTACTPATH = local.contacthtmlname
  }
}

# Generate a random 64 char string to use in the referer the string that CF passes to its origin
resource "random_password" "refererstring" {
  length  = 64
  special = false
}

resource "random_integer" "s3suffix" {
  min = 3
  max = 6
}



# All the depends_on statements below ultimately fixed my issue of not being able to create a bucket policy. It was trying to create it before the bucket was created
# Create the S3 bucket that will host the static site
resource "aws_s3_bucket" "bucket" {
  bucket = "${var.BucketName}-${random_integer.s3suffix.id}"
  tags = {
    Name = "${var.BucketName}-${random_integer.s3suffix.id}"
  }
}

# Configure the S3 bucket to not block public access
resource "aws_s3_bucket_public_access_block" "bucket" {
  bucket                  = aws_s3_bucket.bucket.id
  block_public_acls       = false
  ignore_public_acls      = false
  block_public_policy     = false
  restrict_public_buckets = false
  depends_on              = [aws_s3_bucket.bucket]
}

# Configure the bucket with a policy that only allows traffic containing a specific referer header through (ie. only CF can get data from the bucket)
resource "aws_s3_bucket_policy" "bucket" {
  bucket     = aws_s3_bucket.bucket.id
  policy     = data.aws_iam_policy_document.s3publicaccess.json
  depends_on = [aws_s3_bucket_public_access_block.bucket]
}

# Upload the JS file to the bucket. Use the Templatefile() function to dynamically update the address of the APIGW in the file.
resource "aws_s3_object" "javascript" {
  key          = local.jsname
  bucket       = aws_s3_bucket.bucket.id
  content      = templatefile("${path.module}/../web-fe/index.js", { APIGWURL = var.APIGWInvokeURL }) #@# HERE
  content_type = "text/javascript"
  depends_on   = [aws_s3_bucket_policy.bucket]
  #@# Consider using the Source_hash or etag attribute which should notice any changes to the source content
  ### If the Source_hash changes, it knows the soruce file has changed, and to reupload it
  source_hash = filemd5("${path.module}/../web-fe/index.js")
}

# Upload all HTML files to the bucket. Use the Templatefile() function to dynamically update values in the HTML files.
resource "aws_s3_object" "htmls" {
  for_each = local.htmlmap
  key     = each.value
  bucket  = aws_s3_bucket.bucket.id
  content = templatefile("${path.module}/../web-fe/${each.key}", local.templatefilemap)
  # How I learned I needed to set content type: https://stackoverflow.com/questions/18296875/amazon-s3-downloads-index-html-instead-of-serving
  content_type = "text/html"
  depends_on   = [aws_s3_bucket_policy.bucket]
  # If the Source_hash changes, it knows the soruce file has changed, and to reupload it
  source_hash = filemd5("${path.module}/../web-fe/${each.key}")
}


# Configure the bucket for Static Hosting
resource "aws_s3_bucket_website_configuration" "bucket" {
  bucket = aws_s3_bucket.bucket.id
  index_document {
    suffix = local.homehtmlname
  }
  error_document {
    key = local.errorhtmlname
  }
  depends_on = [aws_s3_object.homehtml, aws_s3_object.resumehtml, aws_s3_object.bloghtml, aws_s3_object.javascript]
}

# CERT MUST BE BUILT IN US-EAST-1 to use with CF
# Create a certificate for the alternative site name
resource "aws_acm_certificate" "certificate" {
  provider          = aws.east1
  domain_name       = "${var.WebSiteHostName}.${var.HostedZone}"
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "certificate" {
  for_each = {
    for dvo in aws_acm_certificate.certificate.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.zone.zone_id
}


## not sure if provider is necessary here
resource "aws_acm_certificate_validation" "certificate" {
  provider                = aws.east1
  certificate_arn         = aws_acm_certificate.certificate.arn
  validation_record_fqdns = [for record in aws_route53_record.certificate : record.fqdn]
}

# Web ACL: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_web_acl
resource "aws_wafv2_web_acl" "cfwebacl" {
  provider    = aws.east1
  name        = "cfwebacl-${random_integer.s3suffix.id}"
  description = "WebACL for CF distro - all AWS managed rules"
  scope       = "CLOUDFRONT"

  default_action {
    allow {}
  }

  rule {
    name     = "managed-IPReputation-rule"
    priority = 0

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "CF-WEBACL-IPREP-METRIC"
      sampled_requests_enabled   = true
    }
    override_action {
      none {}
    }
  }

  rule {
    name     = "managed-BotControl-rule"
    priority = 1

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesBotControlRuleSet"
        vendor_name = "AWS"
        managed_rule_group_configs {
          aws_managed_rules_bot_control_rule_set {
            inspection_level = "COMMON"
          }

        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "CF-WEBACL-BOT-METRIC"
      sampled_requests_enabled   = true
    }
    override_action {
      none {}
    }
  }

  rule {
    name     = "managed-common-rule"
    priority = 2

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "CF-WEBACL-COMMON-METRIC"
      sampled_requests_enabled   = true
    }
    override_action {
      none {}
    }
  }

  rule {
    name     = "ratebasedrule"
    priority = 3

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 500
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "CF-WEBACL-RATE-METRIC"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "CF-WEBACL-METRIC"
    sampled_requests_enabled   = true
  }
}

resource "aws_cloudfront_distribution" "distro" {
  enabled = true
  aliases = ["${var.WebSiteHostName}.${var.HostedZone}"]
  ## More info: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_distribution
  web_acl_id = aws_wafv2_web_acl.cfwebacl.arn
  origin {
    origin_id   = aws_s3_bucket_website_configuration.bucket.website_endpoint
    domain_name = aws_s3_bucket_website_configuration.bucket.website_endpoint
    # This site Goes over a way to only allow access to s3 static site through CF using the referer header: https://repost.aws/knowledge-center/cloudfront-serve-static-website
    custom_header {
      name  = "Referer"
      value = random_password.refererstring.result
    }
    custom_origin_config {
      origin_protocol_policy = "http-only"
      http_port              = 80
      https_port             = 443
      origin_ssl_protocols   = ["TLSv1.2"]
    }

  }
  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    viewer_protocol_policy = "redirect-to-https"
    target_origin_id       = aws_s3_bucket_website_configuration.bucket.website_endpoint
    cache_policy_id        = local.cachingdisabledpolicyid
  }
  price_class = "PriceClass_100"


  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }

  ##### THE CERTIFICATE MUST BE IN US-EAST-1
  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.certificate.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  depends_on = [aws_wafv2_web_acl.cfwebacl]
}

resource "aws_route53_record" "resume1" {
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = "${var.WebSiteHostName}.${var.HostedZone}"
  type    = "A"
  alias {
    name                   = aws_cloudfront_distribution.distro.domain_name
    zone_id                = aws_cloudfront_distribution.distro.hosted_zone_id
    evaluate_target_health = true
  }
}