# EKS Module Outputs

# Cluster Information
output "cluster_id" {
  description = "EKS cluster ID"
  value       = aws_eks_cluster.main.id
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.main.name
}

output "cluster_arn" {
  description = "EKS cluster ARN"
  value       = aws_eks_cluster.main.arn
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_security_group_id" {
  description = "EKS cluster security group ID"
  value       = aws_security_group.cluster.id
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = aws_eks_cluster.main.certificate_authority[0].data
}

output "cluster_version" {
  description = "EKS cluster Kubernetes version"
  value       = aws_eks_cluster.main.version
}

output "cluster_platform_version" {
  description = "EKS cluster platform version"
  value       = aws_eks_cluster.main.platform_version
}

output "cluster_status" {
  description = "EKS cluster status"
  value       = aws_eks_cluster.main.status
}

# OIDC Provider Information
output "cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster OIDC Issuer"
  value       = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

# Node Group Information
output "node_group_arns" {
  description = "ARNs of the EKS node groups"
  value       = { for k, v in aws_eks_node_group.main : k => v.arn }
}

output "node_group_status" {
  description = "Status of the EKS node groups"
  value       = { for k, v in aws_eks_node_group.main : k => v.status }
}

output "node_group_security_group_id" {
  description = "EKS node group security group ID"
  value       = aws_security_group.node_group.id
}

# IAM Role Information
output "cluster_iam_role_arn" {
  description = "IAM role ARN of the EKS cluster"
  value       = aws_iam_role.cluster.arn
}

output "node_group_iam_role_arn" {
  description = "IAM role ARN of the EKS node group"
  value       = aws_iam_role.node_group.arn
}

# Connection Information
output "kubectl_config" {
  description = "kubectl config file content for connecting to the cluster"
  value = {
    cluster_name     = aws_eks_cluster.main.name
    endpoint        = aws_eks_cluster.main.endpoint
    ca_data         = aws_eks_cluster.main.certificate_authority[0].data
    region          = data.aws_region.current.name
  }
}

# SSM Access Information
output "ssm_connection_guide" {
  description = "Guide for connecting to EKS nodes via SSM"
  value = var.enable_ssm_access ? {
    description = "To connect to EKS nodes via SSM Session Manager:"
    commands = [
      "1. List running instances: aws ec2 describe-instances --filters 'Name=tag:kubernetes.io/cluster/${aws_eks_cluster.main.name},Values=owned' --query 'Reservations[].Instances[].InstanceId' --output table --profile personal",
      "2. Start SSM session: aws ssm start-session --target <instance-id> --profile personal",
      "3. Once connected, you can run kubectl commands as the ec2-user"
    ]
  } : null
}

# Add-ons Information
output "addon_status" {
  description = "Status of EKS add-ons"
  value = {
    vpc_cni         = aws_eks_addon.vpc_cni.status
    coredns         = aws_eks_addon.coredns.status
    kube_proxy      = aws_eks_addon.kube_proxy.status
    ebs_csi_driver  = aws_eks_addon.ebs_csi_driver.status
  }
} 