DDBTableName               = "VisitorCounterTableGATest"
LambdaName                 = "SetVisitorCounterLambdaGATest"
DDBCountAttrName           = "COUNTERVALUEGA"
DDBHashKeyName             = "SITECOUNTERGA"
LambdaRuntime              = "python3.11"
LambdaHandler              = "SetVisitorCounter_Lambda.lambda_handler"
DDBHashKeyCounterValName   = "VisitorCounterGA"
APIGWName                  = "VisitorCounterAPIGA"
DDBDateAttrName            = "UniqueVisitStampGA"
DDBTimestampUniqueDiffDays = 14

