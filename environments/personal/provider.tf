# Provider Configuration for Personal Environment
terraform {
  # Terraform Cloud Backend
  cloud {
    organization = "goteego"  # Replace with your Terraform Cloud organization
    
    workspaces {
      name = "Final-Team2"
    }
  }
}

# Configure AWS Provider for Personal Account
provider "aws" {
  region  = var.aws_region
  profile = "personal"  # AWS CLI profile for personal account
  
  default_tags {
    tags = var.common_tags
  }
} 