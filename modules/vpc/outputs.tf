# VPC Module Outputs

# VPC
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

# Internet Gateway
output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}

# Public Subnets
output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = aws_subnet.public[*].id
}

output "public_subnet_cidrs" {
  description = "List of CIDR blocks of public subnets"
  value       = aws_subnet.public[*].cidr_block
}

# EKS Private Subnets
output "eks_private_subnets" {
  description = "List of IDs of EKS private subnets"
  value       = aws_subnet.eks_private[*].id
}

output "eks_private_subnet_cidrs" {
  description = "List of CIDR blocks of EKS private subnets"
  value       = aws_subnet.eks_private[*].cidr_block
}

# PostgreSQL Private Subnets
output "postgresql_private_subnets" {
  description = "List of IDs of PostgreSQL private subnets"
  value       = aws_subnet.postgresql_private[*].id
}

output "postgresql_private_subnet_cidrs" {
  description = "List of CIDR blocks of PostgreSQL private subnets"
  value       = aws_subnet.postgresql_private[*].cidr_block
}

# MongoDB Private Subnets
output "mongodb_private_subnets" {
  description = "List of IDs of MongoDB private subnets"
  value       = aws_subnet.mongodb_private[*].id
}

output "mongodb_private_subnet_cidrs" {
  description = "List of CIDR blocks of MongoDB private subnets"
  value       = aws_subnet.mongodb_private[*].cidr_block
}

# Elasticache Private Subnets
output "elasticache_private_subnets" {
  description = "List of IDs of Elasticache private subnets"
  value       = aws_subnet.elasticache_private[*].id
}

output "elasticache_private_subnet_cidrs" {
  description = "List of CIDR blocks of Elasticache private subnets"
  value       = aws_subnet.elasticache_private[*].cidr_block
}

# NAT Gateways
output "nat_gateway_ids" {
  description = "List of IDs of NAT Gateways"
  value       = aws_nat_gateway.main[*].id
}

output "nat_gateway_ips" {
  description = "List of public IPs of NAT Gateways"
  value       = aws_eip.nat[*].public_ip
}

# Route Tables
output "public_route_table_id" {
  description = "ID of the public route table"
  value       = aws_route_table.public.id
}

output "private_route_table_ids" {
  description = "List of IDs of private route tables"
  value       = aws_route_table.private[*].id
}

# SSM Endpoints
output "ssm_vpc_endpoint_id" {
  description = "ID of SSM VPC endpoint"
  value       = var.enable_ssm_endpoints && length(aws_vpc_endpoint.ssm) > 0 ? aws_vpc_endpoint.ssm[0].id : null
}

output "ssm_vpc_endpoint_dns_names" {
  description = "DNS names of SSM VPC endpoints"
  value = var.enable_ssm_endpoints && length(aws_vpc_endpoint.ssm) > 0 ? {
    ssm          = aws_vpc_endpoint.ssm[0].dns_entry[0]["dns_name"]
    ssm_messages = aws_vpc_endpoint.ssm_messages[0].dns_entry[0]["dns_name"]
    ec2_messages = aws_vpc_endpoint.ec2_messages[0].dns_entry[0]["dns_name"]
  } : {}
}

# Security Groups
output "ssm_endpoint_security_group_id" {
  description = "ID of SSM endpoint security group"
  value       = var.enable_ssm_endpoints && length(aws_security_group.ssm_endpoint) > 0 ? aws_security_group.ssm_endpoint[0].id : null
}

output "postgresql_sg_id" {
  value = aws_security_group.postgresql.id
}
output "mongodb_sg_id" {
  value = aws_security_group.mongodb.id
}
# Availability Zones
output "availability_zones" {
  description = "List of availability zones used"
  value       = local.azs
} 
output "elasticache_sg_id" {
  value = aws_security_group.elasticache_sg.id
}