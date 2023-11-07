# The name of the bucket that will be created to host the static website
# ONLY LOWERCASE ALPHANUMERIC CHARS and HYPHENS ALLOWED
variable "BucketName" {
  type = string
}

# A version string that will be used to version the html and js files. This makes it easier to invalidate caches without having to 
# actually invalidate the cache through CF
# Expected Format: "n.m" where n and m are integers
variable "WebCodeVersion" {
  type = string
}

# The name of a public hosted zone that is hosted in Route 53. We will use this variable to import an existing hosted zone 
# as a data source, and use that to create DNS Records and Certs
# Expected Format: exa. dev.justicecorp.org
variable "HostedZone" {
  type = string
}

# The desired hostname for the Alias record to the CloudFront distribution
# The ultiamte format of the DNS Record will be: <WebSiteHostName>.<HostedZone>
# Expected Format: any valid hostname from the DNS perspective
variable "WebSiteHostName" {
  type = string
}

variable "BackendState" {
  type = string
}