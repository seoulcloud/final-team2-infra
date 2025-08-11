# ALB Module Outputs

# IAM Role for AWS Load Balancer Controller (from IRSA module)
output "aws_load_balancer_controller_role_arn" {
  description = "ARN of the AWS Load Balancer Controller IAM role"
  value       = module.aws_load_balancer_controller_irsa.iam_role_arn
}

output "aws_load_balancer_controller_role_name" {
  description = "Name of the AWS Load Balancer Controller IAM role"
  value       = module.aws_load_balancer_controller_irsa.iam_role_name
}

# IAM Policy
output "aws_load_balancer_controller_policy_arn" {
  description = "ARN of the AWS Load Balancer Controller IAM policy"
  value       = aws_iam_policy.aws_load_balancer_controller.arn
}

# Security Group
output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = aws_security_group.alb.id
}

output "alb_security_group_arn" {
  description = "ARN of the ALB security group"
  value       = aws_security_group.alb.arn
}

# Service Account information
output "service_account_name" {
  description = "AWS Load Balancer Controller service account name"
  value       = module.aws_load_balancer_controller_irsa.service_account_name
}

output "service_account_namespace" {
  description = "AWS Load Balancer Controller service account namespace"
  value       = module.aws_load_balancer_controller_irsa.service_account_namespace
}

# Helm values for AWS Load Balancer Controller
output "helm_values" {
  description = "Recommended Helm values for AWS Load Balancer Controller"
  value = {
    clusterName = var.cluster_name
    serviceAccount = {
      create = false # IRSA 모듈에서 생성했으므로 false
      name   = module.aws_load_balancer_controller_irsa.service_account_name
      annotations = {
        "eks.amazonaws.com/role-arn" = module.aws_load_balancer_controller_irsa.iam_role_arn
      }
    }
    region = data.aws_region.current.name
    vpcId  = var.vpc_id
  }
} 