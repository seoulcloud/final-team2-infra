terraform {
  cloud {
    organization = "goteego"

    workspaces {
      name = "final-team2-infra" # goteego는 회사계정 Final-Team2(김재신)
    }
  }
}
# test 3
# Configure AWS Provider for Team Account
provider "aws" {
  region  = var.aws_region
  # profile = "default"  # AWS CLI profile for team account

  default_tags {
    tags = var.common_tags
  }
} 
