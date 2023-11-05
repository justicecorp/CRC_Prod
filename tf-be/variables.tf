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
