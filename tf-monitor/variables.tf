# This is the URL of the webhook for the Zenduty Service AWS Cloudwatchv2 integration 
# This is the URL of a destination for one of the subscribtions of the SNS topic created in this module
# THIS WILL BE PASSED IN BY THE GITHUB ACTIONS SCRIPT - DO NOT DEFINE IT 
variable "ZendutyServiceWebhook" {
  type = string
}

variable "LambdaName" {
  type = string
}

variable "CloudFrontID" {
  type = string
}

variable "APIGWName" {
  type = string
}