# This runs every time Plan is run. IT WILL ALWAYS OVERWRITE THE EXISTING ZIP FILE
# This Data Source generates an archive (type choosable) from a given path to a specified path
data "archive_file" "lambdaZip" {
  type        = "zip"
  output_path = "${path.module}/../web-be/lambda.zip"
  source_dir  = "${path.module}/../web-be/lambda/"
}

# Returns the region the default provider is configured for
data "aws_region" "current" {}
