# create and upload data to S3 here

locals {
  htmlname                 = "index_${var.WebCodeVersion}.html"
  jsname                   = "index_${var.WebCodeVersion}.js"
  cforiginid               = "myS3staticOrigin"
  cachingoptimizedpolicyid = "658327ea-f89d-4fab-a63d-7e88639e58f6"
  cachingdisabledpolicyid  = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
}

resource "random_password" "refererstring" {
  length  = 64
  special = false
}

# All the depends_on statements below ultimately fixed my issue of not being able to create a bucket policy. 
resource "aws_s3_bucket" "bucket" {
  bucket = var.BucketName
  tags = {
    Name = var.BucketName
  }
}

resource "aws_s3_bucket_public_access_block" "bucket" {
  bucket                  = aws_s3_bucket.bucket.id
  block_public_acls       = false
  ignore_public_acls      = false
  block_public_policy     = false
  restrict_public_buckets = false
  depends_on              = [aws_s3_bucket.bucket]
}

resource "aws_s3_bucket_policy" "bucket" {
  bucket     = aws_s3_bucket.bucket.id
  policy     = data.aws_iam_policy_document.s3publicaccess.json
  depends_on = [aws_s3_bucket_public_access_block.bucket]
}

resource "aws_s3_object" "javascript" {
  key          = local.jsname
  bucket       = aws_s3_bucket.bucket.id
  content      = templatefile("${path.module}/../web-fe/index.js.tftpl", { APIGWURL = data.terraform_remote_state.beoutput.outputs.APIGW-invokeurl }) #@# HERE
  content_type = "text/javascript"
  depends_on   = [aws_s3_bucket_policy.bucket]
  
}

resource "aws_s3_object" "html" {
  key     = local.htmlname
  bucket  = aws_s3_bucket.bucket.id
  content = templatefile("${path.module}/../web-fe/index.html.tftpl", { JAVASCRIPTPATH = local.jsname })
  # How I learned I needed to set content type: https://stackoverflow.com/questions/18296875/amazon-s3-downloads-index-html-instead-of-serving
  content_type = "text/html"
  depends_on   = [aws_s3_bucket_policy.bucket]
}

resource "aws_s3_bucket_website_configuration" "bucket" {
  bucket = aws_s3_bucket.bucket.id
  index_document {
    suffix = local.htmlname
  }

  error_document {
    key = local.htmlname
  }
  depends_on = [aws_s3_object.html, aws_s3_object.javascript]
}

### CERT MUST BE BUILT IN US-EAST-1 to use with CF
#create a certificate in an existing r53 hosted zone
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

resource "aws_cloudfront_distribution" "distro" {
  enabled = true
  aliases = ["${var.WebSiteHostName}.${var.HostedZone}"]
  origin {
    origin_id   = aws_s3_bucket_website_configuration.bucket.website_endpoint
    domain_name = aws_s3_bucket_website_configuration.bucket.website_endpoint
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
    # Add the referer header here
    #custom_header {}
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
}
# create cloudfront distro
#@#@#@#@# Goes over a way to only allow access to s3 static site through CF: https://repost.aws/knowledge-center/cloudfront-serve-static-website
## uses a referer header. Cloudfront always sends its request to the site with custom header that has a secret key. S3 only accepts requests with that header.
# define the ami of the cert as a variable

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