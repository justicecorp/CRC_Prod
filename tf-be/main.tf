terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.21.0"
    }
  }
}

locals {
  roleName      = "lambda-er-${var.DDBTableName}-IAMRole"
  policyNameDDB = "lambda-er-${var.DDBTableName}-IAMPolicy-DDB"
  policyNameCW  = "lambda-er-${var.DDBTableName}-IAMPolicy-CW"
}

# Create Dynamo DB table in on-demand mode with a hash key that will hold both the Site Counter value and hashes of IPs of users who have visited
resource "aws_dynamodb_table" "sitecounterddbtable" {
  name         = var.DDBTableName
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = var.DDBHashKeyName

  attribute {
    name = var.DDBHashKeyName
    type = "S"
  }
}

# Create the role that will be used as the Lambda Execution Role
resource "aws_iam_role" "Lambda-DDBTable-Role" {
  name = local.roleName
  assume_role_policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Principal" : {
            "Service" : "lambda.amazonaws.com"
          },
          "Action" : "sts:AssumeRole"
        }
      ]
    }
  )
  depends_on = [aws_dynamodb_table.sitecounterddbtable]
}

# Create a permissions policy that allows writing to CloudWatch Logs
resource "aws_iam_policy" "Lambda-DDBTable-CloudWatchPolicy" {
  name        = local.policyNameCW
  path        = "/"
  description = "Permissions policy giving a Lambda fxn access to CW"
  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Sid" : "CloudWatchAccess"
          "Effect" : "Allow",
          "Action" : [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ],
          "Resource" : "*"
        }
      ]
    }
  )
  depends_on = [aws_dynamodb_table.sitecounterddbtable]
}

# Create a Role-Policy attachment to associate the role with the CloudWatch Permissions policy
resource "aws_iam_role_policy_attachment" "CWPolicyAttachment" {
  role       = aws_iam_role.Lambda-DDBTable-Role.name
  policy_arn = aws_iam_policy.Lambda-DDBTable-CloudWatchPolicy.arn
  depends_on = [aws_dynamodb_table.sitecounterddbtable]
}

# Create a permissions policy that allows full access to DynamoDB
#@# Need to dramatically limit this. Could even create this after the DDB table is created and only give it access to the DDB table.
resource "aws_iam_policy" "Lambda-DDBTable-DDBAccessPolicy" {
  name        = local.policyNameDDB
  path        = "/"
  description = "Permissions policy giving a Lambda fxn access to DDB"
  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Sid"    : "ReadWriteSpecificDDBTable",
          "Action" : "dynamodb:*",
          "Effect" : "Allow",
          "Resource" : "${aws_dynamodb_table.sitecounterddbtable.arn}"
        },
        {
          "Action" : "cloudwatch:GetInsightRuleReport",
          "Effect" : "Allow",
          "Resource" : "arn:aws:cloudwatch:*:*:insight-rule/DynamoDBContributorInsights*"
        }
      ]
    }
  )
  depends_on = [aws_dynamodb_table.sitecounterddbtable]
}

# Create a Role-Policy attachment to associate the role with the DynamoDB Permissions policy
resource "aws_iam_role_policy_attachment" "DDBPolicyAttachment" {
  role       = aws_iam_role.Lambda-DDBTable-Role.name
  policy_arn = aws_iam_policy.Lambda-DDBTable-DDBAccessPolicy.arn
  depends_on = [aws_dynamodb_table.sitecounterddbtable]
}

# Create a Lambda function with a zip file as its source
# Must use Environment Variables in my python script so it can remain static and work regardless of the naming conventions I use with DDB
resource "aws_lambda_function" "sitecounterlambda" {
  function_name = var.LambdaName
  role          = aws_iam_role.Lambda-DDBTable-Role.arn
  filename      = data.archive_file.lambdaZip.output_path
  handler       = var.LambdaHandler
  # This should take care of updating the lambda fxn if the archive file changes
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
  depends_on = [aws_iam_role_policy_attachment.CWPolicyAttachment, aws_iam_role_policy_attachment.DDBPolicyAttachment]
}

## Web ACL: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_web_acl
resource "aws_wafv2_web_acl" "apigwwebacl" {
  name        = "APIGWwebacl"
  description = "WebACL for APIGW - all AWS managed rules"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "managed-IPReputation-rule"
    priority = 0

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "APIGW-WEBACL-IPREP-METRIC"
      sampled_requests_enabled   = true
    }
    override_action {
      none {}
    }
  }

  rule {
    name     = "managed-BotControl-rule"
    priority = 1

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesBotControlRuleSet"
        vendor_name = "AWS"
        managed_rule_group_configs {
          aws_managed_rules_bot_control_rule_set {
            inspection_level = "COMMON"
          }

        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "APIGW-WEBACL-BOT-METRIC"
      sampled_requests_enabled   = true
    }
    override_action {
      none {}
    }
  }

  rule {
    name     = "managed-common-rule"
    priority = 2

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "APIGW-WEBACL-COMMON-METRIC"
      sampled_requests_enabled   = true
    }
    override_action {
      none {}
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "APIGW-WEBACL-METRIC"
    sampled_requests_enabled   = true
  }
}

# Create API Gateway with Lambda Proxy Integration enabled that will point to my lambda
resource "aws_api_gateway_rest_api" "lambdaAPI" {
  name = var.APIGWName
  endpoint_configuration {
    types = ["REGIONAL"]
  }
  depends_on = [aws_wafv2_web_acl.apigwwebacl]
}

# Create the only API Gateway Method that will be needed - POST 
resource "aws_api_gateway_method" "method" {
  rest_api_id   = aws_api_gateway_rest_api.lambdaAPI.id
  resource_id   = aws_api_gateway_rest_api.lambdaAPI.root_resource_id
  http_method   = "POST"
  authorization = "NONE"
}

# Enable the APUI Gateway for Lambda Proxy Integration and point it at the Lambda
resource "aws_api_gateway_integration" "integration" {
  rest_api_id             = aws_api_gateway_rest_api.lambdaAPI.id
  resource_id             = aws_api_gateway_rest_api.lambdaAPI.root_resource_id
  http_method             = aws_api_gateway_method.method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.sitecounterlambda.invoke_arn
}

# Create an API Gateway Deployment to actually make the API available. 
# The Triggers field will make sure the Deployment object is redeployed if the method or integration change
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

# Create a stage and push the deployment to it. At this point the API is publicly available.
resource "aws_api_gateway_stage" "lambdaAPI" {
  deployment_id = aws_api_gateway_deployment.lambdaAPI.id
  rest_api_id   = aws_api_gateway_rest_api.lambdaAPI.id
  stage_name    = "PROD"
}

resource "aws_api_gateway_method_settings" "all" {
  rest_api_id = aws_api_gateway_rest_api.lambdaAPI.id
  stage_name  = aws_api_gateway_stage.lambdaAPI.stage_name
  method_path = "*/*"

  # Set the rate and burst throttling limits to prevent too many requests. 
  # The metric and log levels might be changed later
  # Sources: https://beabetterdev.com/2021/10/01/aws-api-gateway-request-throttling/ & https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_method_settings
  settings {
    #metrics_enabled = true
    #logging_level   = "ERROR"
    throttling_burst_limit = 500
    throttling_rate_limit  = 1000
  }
}


# Create the Lambda policy that allows the API Gateway to call the Lambda
resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.sitecounterlambda.function_name
  principal     = "apigateway.amazonaws.com"

  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  source_arn = "${aws_api_gateway_rest_api.lambdaAPI.execution_arn}/*/${aws_api_gateway_method.method.http_method}/"
}

resource "aws_wafv2_web_acl_association" "apigwwebacl" {
  resource_arn = aws_api_gateway_stage.lambdaAPI.arn
  web_acl_arn  = aws_wafv2_web_acl.apigwwebacl.arn
  depends_on   = [aws_api_gateway_stage.lambdaAPI, aws_wafv2_web_acl.apigwwebacl]

  timeouts {
    create = "20m"
  }
}

