DDBTableName               = "VisitorCounterTableComb"
LambdaName                 = "SetVisitorCounterLambdaComb"
DDBCountAttrName           = "COUNTERVALUECOMB"
DDBHashKeyName             = "SITECOUNTERCOMB"
LambdaRuntime              = "python3.11"
LambdaHandler              = "SetVisitorCounter_Lambda.lambda_handler"
DDBHashKeyCounterValName   = "VisitorCounterComb"
APIGWName                  = "VisitorCounterAPICombChange"
DDBDateAttrName            = "UniqueVisitStampCombChange"
DDBTimestampUniqueDiffDays = 14
# ONLY LOWERCASE ALPHANUMERIC CHARS and HYPHENS ALLOWED
BucketName     = "visitorcounter-justicecorpcomb"
WebCodeVersion = "3.0"
# Must have the hosted zone pre-created
WebSiteHostName = "resumerealcomb"
HostedZone      = "dev.justicecorp.org"
