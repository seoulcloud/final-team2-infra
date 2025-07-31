# Provider Configuration for Team Environment
terraform {
  # Terraform Cloud Backend
  cloud {
    organization = "goteego" # Replace with your Terraform Cloud organization

    workspaces {
      name = "goteego"
    }
  }
}

# Configure AWS Provider for Team Account
provider "aws" {
  region  = var.aws_region
  # profile = "default"  # AWS CLI profile for team account

  default_tags {
    tags = var.common_tags
  }
} 