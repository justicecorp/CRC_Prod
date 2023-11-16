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

  # must keep this empty because these values are passed into the init command using Github vars in the Github workflows
  backend "s3" {
    bucket         = "tf-tutorial-state"
    key            = "githubactions/tfstate/webacltesting"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
  }
}

provider "aws" {
  region  = "us-west-1"
  profile = "SSOAdminDev"
}

provider "aws" {
  alias   = "east1"
  region  = "us-east-1"
  profile = "SSOAdminDev"
}