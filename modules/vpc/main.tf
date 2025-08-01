# VPC Module - Main Configuration

# Create VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-vpc"
    Type = "VPC"
  })
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-igw"
    Type = "InternetGateway"
  })
}

# Get first 2 AZs for multi-AZ deployment
locals {
  azs = slice(var.availability_zones, 0, 2)
}

# EKS Private Subnets (2 AZs)
resource "aws_subnet" "eks_private" {
  count = length(var.eks_private_subnets)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.eks_private_subnets[count.index]
  availability_zone = local.azs[count.index]

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-EKS-private-subnet-${substr(local.azs[count.index], -1, 1)}"
    Type = "EKS-Private-Subnet"
    "kubernetes.io/role/internal-elb" = "1" # 내부서비스용 LB는 이서브넷에 생성
    "kubernetes.io/cluster/${var.project_name}-${var.environment}-cluster" = "owned"
  })
}

# PostgreSQL Private Subnets (2 AZs)
resource "aws_subnet" "postgresql_private" {
  count = length(var.postgresql_private_subnets)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.postgresql_private_subnets[count.index]
  availability_zone = local.azs[count.index]

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-PostgreSQL-private-subnet-${substr(local.azs[count.index], -1, 1)}"
    Type = "PostgreSQL-Private-Subnet"
    Database = "PostgreSQL"
  })
}

# MongoDB Private Subnets (2 AZs)
resource "aws_subnet" "mongodb_private" {
  count = length(var.mongodb_private_subnets)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.mongodb_private_subnets[count.index]
  availability_zone = local.azs[count.index]

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-MongoDB-private-subnet-${substr(local.azs[count.index], -1, 1)}"
    Type = "MongoDB-Private-Subnet"
    Database = "MongoDB"
  })
}

# Elasticache Private Subnets (2 AZs)
resource "aws_subnet" "elasticache_private" {
  count = length(var.elasticache_private_subnets)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.elasticache_private_subnets[count.index]
  availability_zone = local.azs[count.index]

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-Elasticache-private-subnet-${substr(local.azs[count.index], -1, 1)}"
    Type = "Elasticache-Private-Subnet"
    Database = "Elasticache"
  })
}



# Elastic IPs for NAT Gateways
resource "aws_eip" "nat" {
  count = 2  # One for each AZ

  domain = "vpc"
  depends_on = [aws_internet_gateway.main]

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-eip-nat-${count.index + 1}"
    Type = "NAT-EIP"
  })
}

# Public Subnets for NAT Gateways
resource "aws_subnet" "public" {
  count = 2

  vpc_id                  = aws_vpc.main.id
  cidr_block             = cidrsubnet(var.vpc_cidr, var.public_subnet_newbits, count.index)
  availability_zone      = local.azs[count.index]
  map_public_ip_on_launch = true

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-public-subnet-${count.index + 1}"
    Type = "Public-Subnet"
  })
}

# NAT Gateways
resource "aws_nat_gateway" "main" {
  count = 2

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  depends_on    = [aws_internet_gateway.main]

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-nat-${count.index + 1}"
    Type = "NAT-Gateway"
  })
}

# Route Table for Public Subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = var.internet_cidr
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-public-rt"
    Type = "PublicRouteTable"
  })
}

# Associate Public Subnets with Public Route Table
resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Route Tables for Private Subnets (one per AZ for redundancy)
resource "aws_route_table" "private" {
  count = 2

  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = var.internet_cidr
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-private-rt-${count.index + 1}"
    Type = "PrivateRouteTable"
  })
}

# Associate EKS Private Subnets with Route Tables
resource "aws_route_table_association" "eks_private" {
  count = length(aws_subnet.eks_private)

  subnet_id      = aws_subnet.eks_private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# Associate PostgreSQL Private Subnets with Route Tables
resource "aws_route_table_association" "postgresql_private" {
  count = length(aws_subnet.postgresql_private)

  subnet_id      = aws_subnet.postgresql_private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# Associate MongoDB Private Subnets with Route Tables
resource "aws_route_table_association" "mongodb_private" {
  count = length(aws_subnet.mongodb_private)

  subnet_id      = aws_subnet.mongodb_private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# Associate Elasticache Private Subnets with Route Tables
resource "aws_route_table_association" "elasticache_private" {
  count = length(aws_subnet.elasticache_private)

  subnet_id      = aws_subnet.elasticache_private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}


# SSM VPC Endpoints (Required for private subnet access)
resource "aws_vpc_endpoint" "ssm" {
  count = var.enable_ssm_endpoints ? 1 : 0 # 조건부생성 true | false

  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.eks_private[*].id
  security_group_ids  = [aws_security_group.ssm_endpoint[0].id]
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = "*"
        Action = var.ssm_actions
        Resource = "*"
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-ssm-endpoint"
    Type = "SSM-VPC-Endpoint"
  })
}

resource "aws_vpc_endpoint" "ssm_messages" {
  count = var.enable_ssm_endpoints ? 1 : 0

  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.eks_private[*].id
  security_group_ids  = [aws_security_group.ssm_endpoint[0].id]

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-ssm-messages-endpoint"
    Type = "SSM-Messages-VPC-Endpoint"
  })
}

resource "aws_vpc_endpoint" "ec2_messages" {
  count = var.enable_ssm_endpoints ? 1 : 0

  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.ec2messages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.eks_private[*].id
  security_group_ids  = [aws_security_group.ssm_endpoint[0].id]

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-ec2-messages-endpoint"
    Type = "EC2-Messages-VPC-Endpoint"
  })
}

# Security Group for SSM VPC Endpoints
resource "aws_security_group" "ssm_endpoint" {
  count = var.enable_ssm_endpoints ? 1 : 0

  name_prefix = "${var.project_name}-${var.environment}-ssm-endpoint-"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = var.https_port
    to_port     = var.https_port
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "HTTPS from VPC"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.internet_cidr]
    description = "All outbound traffic"
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-ssm-endpoint-sg"
    Type = "SSM-Endpoint-SecurityGroup"
  })

  lifecycle {
    create_before_destroy = true
  }
} 

# Security Group for PostgreSQL 

resource "aws_security_group" "postgresql" {
  name        = "${var.project_name}-${var.environment}-postgresql-sg"
  description = "Allow PostgreSQL access"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]  # 내부에서만 접근 허용
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-postgresql-sg"
    Type = "PostgreSQL-SG"
  })
}


# Security Group for MongoDB 

resource "aws_security_group" "mongodb" {
  name        = "${var.project_name}-${var.environment}-mongodb-sg"
  description = "Allow MongoDB access"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-mongodb-sg"
    Type = "MongoDB-SG"
  })
}