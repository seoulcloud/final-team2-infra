# EKS Module - Main Configuration

# Data source for current AWS caller identity
data "aws_caller_identity" "current" {}

# Data source for current AWS region
data "aws_region" "current" {}

# EKS Cluster IAM Role
resource "aws_iam_role" "cluster" {
  name = "${var.project_name}-${var.environment}-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-eks-cluster-role"
    Type = "EKS-Cluster-IAM-Role"
  })
}

# Attach required policies to EKS cluster role
resource "aws_iam_role_policy_attachment" "cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}

# EKS Node Group IAM Role
resource "aws_iam_role" "node_group" {
  name = "${var.project_name}-${var.environment}-eks-node-group-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-eks-node-group-role"
    Type = "EKS-NodeGroup-IAM-Role"
  })
}

# Attach required policies to node group role
resource "aws_iam_role_policy_attachment" "node_group_worker_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node_group.name
}

resource "aws_iam_role_policy_attachment" "node_group_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node_group.name
}

resource "aws_iam_role_policy_attachment" "node_group_registry_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node_group.name
}

# SSM Access for EKS Nodes
resource "aws_iam_role_policy_attachment" "node_group_ssm_policy" {
  count = var.enable_ssm_access ? 1 : 0
  
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.node_group.name
}

# Additional SSM permissions for EKS nodes
resource "aws_iam_role_policy" "node_group_ssm_custom" {
  count = var.enable_ssm_access ? 1 : 0
  
  name = "${var.project_name}-${var.environment}-eks-node-ssm-custom"
  role = aws_iam_role.node_group.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:UpdateInstanceInformation",
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel",
          "ec2messages:*"
        ]
        Resource = "*"
      }
    ]
  })
}

# EBS CSI Driver IAM Policy
resource "aws_iam_policy" "ebs_csi_driver" {
  name        = "${var.project_name}-${var.environment}-ebs-csi-driver-policy"
  description = "EBS CSI driver policy for EKS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:AttachVolume",
          "ec2:CreateSnapshot",
          "ec2:CreateTags",
          "ec2:CreateVolume",
          "ec2:DeleteSnapshot",
          "ec2:DeleteTags",
          "ec2:DeleteVolume",
          "ec2:DescribeInstances",
          "ec2:DescribeSnapshots",
          "ec2:DescribeTags",
          "ec2:DescribeVolumes",
          "ec2:DetachVolume"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-ebs-csi-driver-policy"
    Type = "IAM-Policy"
  })
}

# EBS CSI Driver IAM Role
resource "aws_iam_role" "ebs_csi_driver" {
  name = "${var.project_name}-${var.environment}-ebs-csi-driver-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.eks.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(aws_eks_cluster.main.identity[0].oidc[0].issuer, "https://", "")}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
          }
        }
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-ebs-csi-driver-role"
    Type = "IAM-Role"
  })
}

# Attach EBS CSI Driver policy to role
resource "aws_iam_role_policy_attachment" "ebs_csi_driver" {
  role       = aws_iam_role.ebs_csi_driver.name
  policy_arn = aws_iam_policy.ebs_csi_driver.arn
}

# EKS Cluster Security Group
resource "aws_security_group" "cluster" {
  name_prefix = "${var.project_name}-${var.environment}-eks-cluster-"
  vpc_id      = var.vpc_id

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.internet_cidr]
    description = "All outbound traffic"
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-eks-cluster-sg"
    Type = "EKS-Cluster-SecurityGroup"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# EKS Node Group Security Group
resource "aws_security_group" "node_group" {
  name_prefix = "${var.project_name}-${var.environment}-eks-node-"
  vpc_id      = var.vpc_id

  # Allow inbound traffic from cluster security group
  ingress {
    from_port       = 0
    to_port         = var.high_port
    protocol        = "tcp"
    security_groups = [aws_security_group.cluster.id]
    description     = "Allow all TCP from cluster security group"
  }

  # Allow nodes to communicate with each other
  ingress {
    from_port = 0
    to_port   = var.high_port
    protocol  = "tcp"
    self      = true
    description = "Allow nodes to communicate with each other"
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.internet_cidr]
    description = "All outbound traffic"
  }

  # HTTPS for SSM communication (Session Manager, Messages, etc.)
  ingress {
    from_port   = var.https_port
    to_port     = var.https_port
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "HTTPS for SSM Session Manager and Messages"
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-eks-node-sg"
    Type = "EKS-NodeGroup-SecurityGroup"
  })

  lifecycle {
    create_before_destroy = true
  }
}

  # Security group rules for cluster to communicate with nodes
resource "aws_security_group_rule" "cluster_to_node" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = var.high_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.node_group.id
  security_group_id        = aws_security_group.cluster.id
  description              = "Allow cluster to communicate with nodes"
}

# EKS Cluster
resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  role_arn = aws_iam_role.cluster.arn
  version  = var.cluster_version

  vpc_config {
    subnet_ids              = var.eks_private_subnets
    security_group_ids      = [aws_security_group.cluster.id]
    endpoint_private_access = var.cluster_endpoint_config.private_access
    endpoint_public_access  = var.cluster_endpoint_config.public_access
    public_access_cidrs     = var.cluster_endpoint_config.public_access_cidrs
  }

  # Enable EKS cluster logging
  enabled_cluster_log_types = var.cluster_log_types

  depends_on = [
    aws_iam_role_policy_attachment.cluster_policy,
  ]

  tags = merge(var.common_tags, {
    Name = var.cluster_name
    Type = "EKS-Cluster"
  })
}

# OIDC Provider for EKS
data "tls_certificate" "oidc_thumbprint" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.oidc_thumbprint.certificates[0].sha1_fingerprint]

  tags = merge(var.common_tags, {
    Name = "${var.cluster_name}-oidc-provider"
    Type = "OIDC-Provider"
  })
}

# EKS Node Groups
resource "aws_eks_node_group" "main" {
  for_each = var.node_groups

  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.cluster_name}-${each.key}"
  node_role_arn   = aws_iam_role.node_group.arn
  subnet_ids      = var.eks_private_subnets

  # Instance configuration
  instance_types = each.value.instance_types
  ami_type       = each.value.ami_type
  capacity_type  = each.value.capacity_type
  

  # Scaling configuration
  scaling_config {
    desired_size = each.value.desired_size
    max_size     = each.value.max_size
    min_size     = each.value.min_size
  }

  # Update configuration
  update_config {
    max_unavailable_percentage = var.max_unavailable_percentage
  }

  # Remote access configuration is handled in launch template for SSM access

  # Launch template for advanced configuration
  launch_template {
    name    = aws_launch_template.node_group[each.key].name
    version = aws_launch_template.node_group[each.key].latest_version
  }

  depends_on = [
    aws_iam_role_policy_attachment.node_group_worker_policy,
    aws_iam_role_policy_attachment.node_group_cni_policy,
    aws_iam_role_policy_attachment.node_group_registry_policy,
    aws_iam_role_policy_attachment.node_group_ssm_policy,
    aws_launch_template.node_group,  # Launch Template 의존성 추가
    aws_eks_access_policy_association.node_group,  # AccessEntry 생성 후 노드 그룹 생성
  ]

  tags = merge(var.common_tags, {
    Name = "${var.cluster_name}-${each.key}"
    Type = "EKS-NodeGroup"
  })

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }
}

# Launch template for EKS nodes with SSM agent
resource "aws_launch_template" "node_group" {
  for_each = var.node_groups

  name_prefix = "${var.cluster_name}-${each.key}-"
  description = "Launch template for EKS node group ${each.key}"

  vpc_security_group_ids = [aws_security_group.node_group.id]

  # User data to ensure SSM agent is running
  user_data = base64encode(templatefile("${path.module}/templates/user-data.sh.tpl", {
    cluster_name        = aws_eks_cluster.main.name
    cluster_endpoint    = aws_eks_cluster.main.endpoint
    cluster_ca          = aws_eks_cluster.main.certificate_authority[0].data
    enable_ssm_access   = var.enable_ssm_access
  }))

  # Instance metadata options
  metadata_options {
    http_endpoint               = var.instance_metadata_options.http_endpoint
    http_tokens                 = var.instance_metadata_options.http_tokens
    http_put_response_hop_limit = var.instance_metadata_options.http_put_response_hop_limit
    instance_metadata_tags      = var.instance_metadata_options.instance_metadata_tags
  }

  # Monitoring
  monitoring {
    enabled = var.monitoring_enabled
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = each.value.disk_size
      volume_type = "gp3"
      delete_on_termination = true
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.common_tags, {
      Name = "${var.cluster_name}-${each.key}-node"
      Type = "EKS-Node"
    })
  }

  tag_specifications {
    resource_type = "volume"
    tags = merge(var.common_tags, {
      Name = "${var.cluster_name}-${each.key}-volume"
      Type = "EKS-Node-Volume"
    })
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(var.common_tags, {
    Name = "${var.cluster_name}-${each.key}-lt"
    Type = "EKS-LaunchTemplate"
  })
}

# EKS Add-ons (AWS managed)
resource "aws_eks_addon" "vpc_cni" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "vpc-cni"
  
  resolve_conflicts_on_create = var.addon_resolve_conflicts
  resolve_conflicts_on_update = var.addon_resolve_conflicts
  
  tags = merge(var.common_tags, {
    Name = "${var.cluster_name}-vpc-cni"
    Type = "EKS-Addon"
  })
}

resource "aws_eks_addon" "coredns" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "coredns"
  
  resolve_conflicts_on_create = var.addon_resolve_conflicts
  resolve_conflicts_on_update = var.addon_resolve_conflicts
  
  depends_on = [
    aws_eks_node_group.main,
    aws_eks_access_policy_association.node_group,  # AccessEntry 생성 후 Add-on 생성
  ]
  
  tags = merge(var.common_tags, {
    Name = "${var.cluster_name}-coredns"
    Type = "EKS-Addon"
  })
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "kube-proxy"
  
  resolve_conflicts_on_create = var.addon_resolve_conflicts
  resolve_conflicts_on_update = var.addon_resolve_conflicts
  
  tags = merge(var.common_tags, {
    Name = "${var.cluster_name}-kube-proxy"
    Type = "EKS-Addon"
  })
}

# EBS CSI Driver for persistent volumes
resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "aws-ebs-csi-driver"
  
  service_account_role_arn = aws_iam_role.ebs_csi_driver.arn
  
  resolve_conflicts_on_create = var.addon_resolve_conflicts
  resolve_conflicts_on_update = var.addon_resolve_conflicts
  
  depends_on = [
    aws_eks_node_group.main,
    aws_eks_access_policy_association.node_group,  # AccessEntry 생성 후 Add-on 생성
  ]
  
  tags = merge(var.common_tags, {
    Name = "${var.cluster_name}-ebs-csi-driver"
    Type = "EKS-Addon"
  })
}

# EKS Access Entry for Node Group IAM Role
resource "aws_eks_access_entry" "node_group" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = aws_iam_role.node_group.arn
  type          = "STANDARD"

  depends_on = [
    aws_eks_cluster.main,
    aws_iam_openid_connect_provider.eks,  # OIDC Provider 생성 후 AccessEntry 생성
  ]

  # EKS 클러스터가 완전히 준비될 때까지 대기
  timeouts {
    create = "10m"
  }
}

# EKS Access Policy for Node Group (system:nodes group access)
resource "aws_eks_access_policy_association" "node_group" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = aws_iam_role.node_group.arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSNodeGroupPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.node_group]
}

# EKS Access Entry for Cluster IAM Role (admin access)
resource "aws_eks_access_entry" "cluster_admin" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = aws_iam_role.cluster.arn
  type          = "STANDARD"

  depends_on = [
    aws_eks_cluster.main,
    aws_iam_openid_connect_provider.eks,  # OIDC Provider 생성 후 AccessEntry 생성
  ]

  # EKS 클러스터가 완전히 준비될 때까지 대기
  timeouts {
    create = "10m"
  }
}

# EKS Access Policy for Cluster Admin (system:masters group access)
resource "aws_eks_access_policy_association" "cluster_admin" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = aws_iam_role.cluster.arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSSystemAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.cluster_admin]
} 