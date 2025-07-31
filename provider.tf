terraform {
  cloud {
    organization = "goteego"

    workspaces {
      name = "Final-Team2" # goteego는 회사계정 Final-Team2 는 개인계정
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
