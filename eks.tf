
# ---------------------------
# VPC
# ---------------------------
resource "aws_vpc" "eks_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "eks_vpc"
  }
}

# ---------------------------
# Subnets (across 2 AZs)
# ---------------------------
resource "aws_subnet" "eks_vpc_subnet_1" {
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "eks_vpc_subnet_1"
  }
}

resource "aws_subnet" "eks_vpc_subnet_2" {
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "ap-south-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "eks_vpc_subnet_2"
  }
}

# ---------------------------
# Internet Gateway + Route
# ---------------------------
resource "aws_internet_gateway" "eks_vpc_ig" {
  vpc_id = aws_vpc.eks_vpc.id

  tags = {
    Name = "eks_vpc_ig"
  }
}

resource "aws_route_table" "eks_vpc_route_table" {
  vpc_id = aws_vpc.eks_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.eks_vpc_ig.id
  }
}

resource "aws_route_table_association" "eks_vpc_route_table_association_sb1" {
  route_table_id = aws_route_table.eks_vpc_route_table.id
  subnet_id      = aws_subnet.eks_vpc_subnet_1.id
}

resource "aws_route_table_association" "eks_vpc_route_table_association_sb2" {
  route_table_id = aws_route_table.eks_vpc_route_table.id
  subnet_id      = aws_subnet.eks_vpc_subnet_2.id
}

# ---------------------------
# Security Group
# ---------------------------
resource "aws_security_group" "eks_vpc_sg" {
  vpc_id = aws_vpc.eks_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "eks_vpc_sg"
  }
}

# ---------------------------
# IAM Role for EKS Cluster
# ---------------------------
resource "aws_iam_role" "eks_cluster_role" {
  name = "eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "eks.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

# ---------------------------
# IAM Role for Worker Nodes
# ---------------------------
resource "aws_iam_role" "eks_node_role" {
  name = "eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_role.name
}

# ---------------------------
# EKS Cluster
# ---------------------------
resource "aws_eks_cluster" "eks_cluster" {
  name     = "my-eks-cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = "1.31"

  vpc_config {
    subnet_ids         = [aws_subnet.eks_vpc_subnet_1.id, aws_subnet.eks_vpc_subnet_2.id]
    security_group_ids = [aws_security_group.eks_vpc_sg.id]
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_AmazonEKSClusterPolicy
  ]
}

# ---------------------------
# EKS Node Group
# ---------------------------
resource "aws_eks_node_group" "eks_nodes" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = "eks-node-group"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = [aws_subnet.eks_vpc_subnet_1.id, aws_subnet.eks_vpc_subnet_2.id]

  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }

  instance_types = ["t2.micro"]

  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy
  ]
}

# ---------------------------
# Outputs
# ---------------------------
output "cluster_name" {
  value = aws_eks_cluster.eks_cluster.name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.eks_cluster.endpoint
}

output "cluster_oidc_issuer" {
  value = aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer
}
