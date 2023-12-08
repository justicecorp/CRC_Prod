
locals {
  resumehtmlname           = "resume_${var.WebCodeVersion}.html"
  homehtmlname             = "home_${var.WebCodeVersion}.html"
  bloghtmlname             = "blog_${var.WebCodeVersion}.html"
  jsname                   = "index_${var.WebCodeVersion}.js"
  cforiginid               = "myS3staticOrigin"
  cachingoptimizedpolicyid = "658327ea-f89d-4fab-a63d-7e88639e58f6"
  cachingdisabledpolicyid  = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
  htmlmap = {
    "blog.html" = local.bloghtmlname
    "resume.html" = local.resumehtmlname
    "home.html" = local.homehtmlname
  }
}

# Upload the Home HTML file to the bucket. Use the Templatefile() function to dynamically update the name of the JS File to import. 
resource "aws_s3_object" "homehtml" {
  key     = local.homehtmlname
  bucket  = aws_s3_bucket.bucket.id
  content = templatefile("${path.module}/../web-fe/home.html", { JAVASCRIPTPATH = local.jsname, BLOGPATH = local.bloghtmlname, RESUMEPATH = local.resumehtmlname, HOMEPATH = local.homehtmlname })
  content_type = "text/html"
  depends_on   = [aws_s3_bucket_policy.bucket]
  source_hash = filemd5("${path.module}/../web-fe/home.html")
}

# Upload the Resume HTML file to the bucket. Use the Templatefile() function to dynamically update the name of the JS File to import. 
resource "aws_s3_object" "resumehtml" {
  key     = local.resumehtmlname
  bucket  = aws_s3_bucket.bucket.id
  content = templatefile("${path.module}/../web-fe/resume.html", { JAVASCRIPTPATH = local.jsname })
  # How I learned I needed to set content type: https://stackoverflow.com/questions/18296875/amazon-s3-downloads-index-html-instead-of-serving
  content_type = "text/html"
  depends_on   = [aws_s3_bucket_policy.bucket]
  #@# Consider using the Source_hash or etag attribute which should notice any changes to the source content
  ### If the Source_hash changes, it knows the soruce file has changed, and to reupload it
  source_hash = filemd5("${path.module}/../web-fe/resume.html")
}

# Upload the HTML file to the bucket. Use the Templatefile() function to dynamically update the name of the JS File to import. 
resource "aws_s3_object" "bloghtml" {
  key     = local.bloghtmlname
  bucket  = aws_s3_bucket.bucket.id
  content = templatefile("${path.module}/../web-fe/blog.html", { JAVASCRIPTPATH = local.jsname })
  # How I learned I needed to set content type: https://stackoverflow.com/questions/18296875/amazon-s3-downloads-index-html-instead-of-serving
  content_type = "text/html"
  depends_on   = [aws_s3_bucket_policy.bucket]
  #@# Consider using the Source_hash or etag attribute which should notice any changes to the source content
  ### If the Source_hash changes, it knows the soruce file has changed, and to reupload it
  source_hash = filemd5("${path.module}/../web-fe/blog.html")
}



resource "aws_s3_object" "htmls" {
  for_each = local.htmlmap
  key     = each.value
  bucket  = aws_s3_bucket.bucket.id
  content = templatefile("${path.module}/../web-fe/${each.key}", { JAVASCRIPTPATH = local.jsname, BLOGPATH = local.bloghtmlname, RESUMEPATH = local.resumehtmlname, HOMEPATH = local.homehtmlname })
  content_type = "text/html"
  depends_on   = [aws_s3_bucket_policy.bucket]
  source_hash = filemd5("${path.module}/../web-fe/${each.key}")
}