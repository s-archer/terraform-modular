terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region                  = var.region
  shared_credentials_file = "~/.aws/credentials"
  profile                 = "Default"
}

provider "github" {
  token = "36cd1b8fa760c5dbbf2774e9b94f26f2daf71def"
  owner = "s-acrher"
}

