terraform {
  required_version = ">= 1.6"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Default provider — uses var.aws_region (e.g. us-east-2)
provider "aws" {
  region = var.aws_region
}

# Alias provider for us-east-1 (required for AWS Billing / EstimatedCharges metrics)
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}
