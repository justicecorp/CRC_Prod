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
          "Action" : [
            "dynamodb:*",
            "dax:*",
            "application-autoscaling:DeleteScalingPolicy",
            "application-autoscaling:DeregisterScalableTarget",
            "application-autoscaling:DescribeScalableTargets",
            "application-autoscaling:DescribeScalingActivities",
            "application-autoscaling:DescribeScalingPolicies",
            "application-autoscaling:PutScalingPolicy",
            "application-autoscaling:RegisterScalableTarget",
            "cloudwatch:DeleteAlarms",
            "cloudwatch:DescribeAlarmHistory",
            "cloudwatch:DescribeAlarms",
            "cloudwatch:DescribeAlarmsForMetric",
            "cloudwatch:GetMetricStatistics",
            "cloudwatch:ListMetrics",
            "cloudwatch:PutMetricAlarm",
            "cloudwatch:GetMetricData",
            "datapipeline:ActivatePipeline",
            "datapipeline:CreatePipeline",
            "datapipeline:DeletePipeline",
            "datapipeline:DescribeObjects",
            "datapipeline:DescribePipelines",
            "datapipeline:GetPipelineDefinition",
            "datapipeline:ListPipelines",
            "datapipeline:PutPipelineDefinition",
            "datapipeline:QueryObjects",
            "ec2:DescribeVpcs",
            "ec2:DescribeSubnets",
            "ec2:DescribeSecurityGroups",
            "iam:GetRole",
            "iam:ListRoles",
            "kms:DescribeKey",
            "kms:ListAliases",
            "sns:CreateTopic",
            "sns:DeleteTopic",
            "sns:ListSubscriptions",
            "sns:ListSubscriptionsByTopic",
            "sns:ListTopics",
            "sns:Subscribe",
            "sns:Unsubscribe",
            "sns:SetTopicAttributes",
            "lambda:CreateFunction",
            "lambda:ListFunctions",
            "lambda:ListEventSourceMappings",
            "lambda:CreateEventSourceMapping",
            "lambda:DeleteEventSourceMapping",
            "lambda:GetFunctionConfiguration",
            "lambda:DeleteFunction",
            "resource-groups:ListGroups",
            "resource-groups:ListGroupResources",
            "resource-groups:GetGroup",
            "resource-groups:GetGroupQuery",
            "resource-groups:DeleteGroup",
            "resource-groups:CreateGroup",
            "tag:GetResources",
            "kinesis:ListStreams",
            "kinesis:DescribeStream",
            "kinesis:DescribeStreamSummary"
          ],
          "Effect" : "Allow",
          "Resource" : "*"
        },
        {
          "Action" : "cloudwatch:GetInsightRuleReport",
          "Effect" : "Allow",
          "Resource" : "arn:aws:cloudwatch:*:*:insight-rule/DynamoDBContributorInsights*"
        },
        {
          "Action" : [
            "iam:PassRole"
          ],
          "Effect" : "Allow",
          "Resource" : "*",
          "Condition" : {
            "StringLike" : {
              "iam:PassedToService" : [
                "application-autoscaling.amazonaws.com",
                "application-autoscaling.amazonaws.com.cn",
                "dax.amazonaws.com"
              ]
            }
          }
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "iam:CreateServiceLinkedRole"
          ],
          "Resource" : "*",
          "Condition" : {
            "StringEquals" : {
              "iam:AWSServiceName" : [
                "replication.dynamodb.amazonaws.com",
                "dax.amazonaws.com",
                "dynamodb.application-autoscaling.amazonaws.com",
                "contributorinsights.dynamodb.amazonaws.com",
                "kinesisreplication.dynamodb.amazonaws.com"
              ]
            }
          }
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
  function_name    = var.LambdaName
  role             = aws_iam_role.Lambda-DDBTable-Role.arn
  filename         = data.archive_file.lambdaZip.output_path
  handler          = var.LambdaHandler
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

# Create API Gateway with Lambda Proxy Integration enabled that will point to my lambda
resource "aws_api_gateway_rest_api" "lambdaAPI" {
  name = var.APIGWName
  endpoint_configuration {
    types = ["REGIONAL"]
  }
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

# Create the Lambda policy that allows the API Gateway to call the Lambda
resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.sitecounterlambda.function_name
  principal     = "apigateway.amazonaws.com"

  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  source_arn = "${aws_api_gateway_rest_api.lambdaAPI.execution_arn}/*/${aws_api_gateway_method.method.http_method}/"
}



