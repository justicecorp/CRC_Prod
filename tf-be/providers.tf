# if you don't specify required_providers and just the provider block, it will still work 
# presumably it will use the latest provider version
terraform {
  # specifies the required provider for this terraform module
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.21.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5.0"
    }
  }

  backend "s3" {
    bucket = "tf-tutorial-state"
    key    = "state_CRCIACPROD"
    region = "us-east-1"
  }
}

provider "aws" {
  region  = "us-east-2"
  profile = "SSOAdminDev"
}

provider "aws" {
  alias   = "east1"
  region  = "us-east-1"
  profile = "SSOAdminDev"
}