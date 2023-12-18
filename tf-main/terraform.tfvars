DDBTableName               = "VisitorCounterTableCombChange"
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
WebCodeVersion = "3.0"


# THIS SHOULD BE PASSED IN THROUGH THE COMMAND LINE
# This is used for the s3 bucketname - make sure it follows s3 naming conventions
#WebSiteHostName = "resumerealcomb"

# THIS SHOULD BE PASSED IN THROUGH THE COMMAND LINE
# Must have the hosted zone pre-created
# This is used for the s3 bucketname - make sure it follows s3 naming conventions
#HostedZone      = "dev.justicecorp.org"
