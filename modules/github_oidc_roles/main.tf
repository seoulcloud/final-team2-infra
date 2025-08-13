variable "github_org" {}
variable "github_repo" {}
variable "s3_bucket_name" {}
variable "cloudfront_distribution_id" {}

data "aws_caller_identity" "current" {}

resource "aws_iam_role" "frontend_deploy_role" {
  name = "goteego-frontend-deploy-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringLike = {
            "token.actions.githubusercontent.com:sub" = [
              "repo:${var.github_org}/${var.github_repo}:ref:refs/heads/main",
              "repo:${var.github_org}/${var.github_repo}:ref:refs/heads/dev"
            ]
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "frontend_deploy_policy" {
  name = "goteego-team-FrontendDeployPolicy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:GetObject"
        ],
        Resource = [
          "arn:aws:s3:::${var.s3_bucket_name}",
          "arn:aws:s3:::${var.s3_bucket_name}/*"
        ]
      },
      {
        Effect   = "Allow",
        Action   = ["cloudfront:CreateInvalidation"],
        Resource = "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/${var.cloudfront_distribution_id}"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_policy" {
  role       = aws_iam_role.frontend_deploy_role.name
  policy_arn = aws_iam_policy.frontend_deploy_policy.arn
}

output "role_arn" {
  value = aws_iam_role.frontend_deploy_role.arn
}