# The name of the DDB Table that will be created
variable "DDBTableName" {
  type = string
}

# The name of the partition key for the DDB Table
variable "DDBHashKeyName" {
  type = string
}

# The name of the DDB Attribute that holds the site counter value. 
variable "DDBCountAttrName" {
  type = string
}

# The name of the DDB Attribute that will hold the name of the user's unique visit timestamp
variable "DDBDateAttrName" {
  type = string
}

# The number of days that have to pass before a repeat visitor is counted as unique
variable "DDBTimestampUniqueDiffDays" {
  type = number
}

# This is the name of the single Hash Key item that will be used to store the counter value
# The rest of the Hash Key items will be literal hash strings of visitors IP addresses
variable "DDBHashKeyCounterValName" {
  type = string
}

# The name of the Lambda function that will be created
variable "LambdaName" {
  type = string
}

# The runtime of the Lambda Function that will be created
variable "LambdaRuntime" {
  type    = string
  default = "python3.11"
}

# The Lambda handler. This will be the python script name and the handler function
# exa. <file name Prefix>.<handler function> -> SetVisitorCount_Lambda.lambda_handler
variable "LambdaHandler" {
  type = string
}

# The name of the API Gateway object that will be created
variable "APIGWName" {
  type = string
}

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

# This is the URL of the webhook for the Zenduty Service AWS Cloudwatchv2 integration 
# This is the URL of a destination for one of the subscribtions of the SNS topic created in this module
# THIS WILL BE PASSED IN BY THE GITHUB ACTIONS SCRIPT - DO NOT DEFINE IT 
variable "ZendutyServiceWebhook" {
  type = string
}