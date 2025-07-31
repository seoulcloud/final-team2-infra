# Terraform and Provider Version Constraints for Personal Environment

# Minimum Terraform version
terraform {
  required_version = ">= 1.0"
}

# Provider version constraints
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
} 