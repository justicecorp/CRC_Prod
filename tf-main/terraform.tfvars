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
BucketName     = "visitorcounter-justicecorp-gha"
WebCodeVersion = "3.0"


# THIS SHOULD BE PASSED IN THROUGH THE COMMAND LINE
#WebSiteHostName = "resumerealcomb"

# THIS SHOULD BE PASSED IN THROUGH THE COMMAND LINE
# Must have the hosted zone pre-created
#HostedZone      = "dev.justicecorp.org"
