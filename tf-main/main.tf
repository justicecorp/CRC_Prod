
module "webapp-be" {
  source                     = "../tf-be"
  DDBTableName               = var.DDBTableName
  DDBHashKeyName             = var.DDBHashKeyName
  DDBCountAttrName           = var.DDBCountAttrName
  DDBDateAttrName            = var.DDBDateAttrName
  DDBTimestampUniqueDiffDays = var.DDBTimestampUniqueDiffDays
  DDBHashKeyCounterValName   = var.DDBHashKeyCounterValName
  LambdaName                 = var.LambdaName
  LambdaRuntime              = var.LambdaRuntime
  LambdaHandler              = var.LambdaHandler
  APIGWName                  = var.APIGWName
}

module "webapp-fe" {
  source          = "../tf-fe"
  BucketName      = var.BucketName
  WebCodeVersion  = var.WebCodeVersion
  HostedZone      = var.HostedZone
  WebSiteHostName = var.WebSiteHostName
  APIGWInvokeURL  = module.webapp-be.APIGW-invokeurl
  providers = {
    aws       = aws
    aws.east1 = aws.east1
  }
}