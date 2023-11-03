

# Create Dynamo DB table in on-demand mode with a hash key that will hold both the site counter var and ip hashes
resource "aws_dynamodb_table" "sitecounterddbtable" {
  name         = var.DDBTableName
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = var.DDBHashKeyName

  attribute {
    name = var.DDBHashKeyName
    type = "S"
  }
}

# create a lambda with a zip file as its source
# must use Environment Variables in my script so it can remain static and work regardless of the naming conventions I use with DDB
resource "aws_lambda_function" "sitecounterlambda" {
  function_name    = var.LambdaName
  role             = aws_iam_role.Lambda-DDBTable-Role.arn
  filename         = data.archive_file.lambdaZip.output_path
  handler          = "${var.LambdaFileNamePrefix}.lambda_handler"
  source_code_hash = data.archive_file.lambdaZip.output_base64sha256
  runtime          = var.LambdaRuntime
  environment {
    variables = {
      ddbcountattr          = var.DDBCountAttrName
      ddbpk                 = aws_dynamodb_table.sitecounterddbtable.hash_key
      ddbtablename          = aws_dynamodb_table.sitecounterddbtable.name
      ddbvisitorcounterpkid = var.DDBHashKeyCounterValName
      regionname            = data.aws_region.current.name
      ddbdateattr           = var.DDBDateAttrName
      ddbuniquediff         = var.DDBTimestampUniqueDiffDays
    }
  }
}

# Create API Gateway with Lambda Proxy Integration that points to my lambda
# API Gateway
resource "aws_api_gateway_rest_api" "lambdaAPI" {
  name = var.APIGWName
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_method" "method" {
  rest_api_id   = aws_api_gateway_rest_api.lambdaAPI.id
  resource_id   = aws_api_gateway_rest_api.lambdaAPI.root_resource_id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "integration" {
  rest_api_id             = aws_api_gateway_rest_api.lambdaAPI.id
  resource_id             = aws_api_gateway_rest_api.lambdaAPI.root_resource_id
  http_method             = aws_api_gateway_method.method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.sitecounterlambda.invoke_arn
}

resource "aws_api_gateway_deployment" "lambdaAPI" {
  rest_api_id = aws_api_gateway_rest_api.lambdaAPI.id

  triggers = {
    # NOTE: The configuration below will satisfy ordering considerations,
    #       but not pick up all future REST API changes. More advanced patterns
    #       are possible, such as using the filesha1() function against the
    #       Terraform configuration file(s) or removing the .id references to
    #       calculate a hash against whole resources. Be aware that using whole
    #       resources will show a difference after the initial implementation.
    #       It will stabilize to only change when resources change afterwards.
    redeployment = sha1(jsonencode([
      aws_api_gateway_method.method.id,
      aws_api_gateway_integration.integration.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "lambdaAPI" {
  deployment_id = aws_api_gateway_deployment.lambdaAPI.id
  rest_api_id   = aws_api_gateway_rest_api.lambdaAPI.id
  stage_name    = "PROD"
}

# Lambda
resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.sitecounterlambda.function_name
  principal     = "apigateway.amazonaws.com"

  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  //source_arn = "arn:aws:execute-api:${data.aws_region.current.name}:${var.accountId}:${aws_api_gateway_rest_api.lambdaAPI.id}/*/${aws_api_gateway_method.method.http_method}${aws_api_gateway_resource.resource.path}"
  #@# Need to figure out if this is correct - may not need the trailing slash at the end. Otherwise it should be good
  # example of manual api method arn arn:aws:execute-api:us-east-1:868381110893:l16a64xfdj/*/POST/
  source_arn = "${aws_api_gateway_rest_api.lambdaAPI.execution_arn}/*/${aws_api_gateway_method.method.http_method}/"
}



