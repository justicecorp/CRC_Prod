variable "DDBTableName" {
  type = string
}

variable "DDBHashKeyName" {
  type = string
}

variable "DDBCountAttrName" {
  type = string
}
# Name of the DDB attr that will hold the name of the user's unique visit timestamp
variable "DDBDateAttrName" {
  type = string
}

variable "DDBTimestampUniqueDiffDays" {
  type = number
}

# this is the name of the single Hash Key item that will be used to store the counter value
# the rest of the Hash Key items will be literal hash strings of visitors IP addresses
variable "DDBHashKeyCounterValName" {
  type = string
}

variable "LambdaName" {
  type = string
}

variable "LambdaRuntime" {
  type = string
}

# the file name of the python file without the file extension that contains the handler
# Could possibly make this the lambda handler 
variable "LambdaFileNamePrefix" {
  type = string
}

variable "APIGWName" {
  type = string
}


variable "BucketName" {
  type = string
}

variable "WebCodeVersion" {
  type = string
}

variable "HostedZone" {
  type = string
}

variable "WebSiteHostName" {
  type = string
}