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

  # Backend is specified in the init command so it can be dynamic. Using Github Repository variables to specify backend
  backend "s3" {
    #bucket         = "tf-tutorial-state"
    #key            = "githubactions/tfstate/backendstate"
    #region         = "us-east-1"
    #dynamodb_table = "terraform-state-lock"
  }
}

# Shouldn't specify profile if it is run through GitHub Actions
provider "aws" {
  region = "us-east-2"
  #profile = "SSOAdminDev"
}

provider "aws" {
  alias  = "east1"
  region = "us-east-1"
  #profile = "SSOAdminDev"
}
