resource "aws_vpc" "eks_vpc" {
    region = "ap-south-1"
    cidr_block = "10.0.0.0/16"
    tags = {
      Name = "eks_vpc"
    }
}

resource "aws_subnet" "eks_vpc_subnet_1" {
    vpc_id = aws_vpc.eks_vpc.id
    cidr_block = "10.0.1.0/24"
    tags  = {
        Name= "eks_vpc_subnet_1"
    }
  
}

resource "aws_subnet" "eks_vpc_subnet_2" {
    vpc_id = aws_vpc.eks_vpc.id
    cidr_block = "10.0.2.0/24"
    tags  = {
        Name= "eks_vpc_subnet_2"
    }
  
}

resource "aws_internet_gateway" "eks_vpc_ig" {

    vpc_id = aws_vpc.eks_vpc.id


    tags = {
      Name ="eks_vpc_ig"
    }
    
  
}

resource "aws_route_table" "eks_vpc_route_table" {
    vpc_id = aws_vpc.eks_vpc.id
    route  {
        cidr_block ="0.0.0.0/0"
        gateway_id = aws_internet_gateway.eks_vpc_ig.id
        
    }
  
}

resource "aws_route_table_association" "eks_vpc_route_table_association_sb1" {

    route_table_id = aws_route_table.eks_vpc_route_table.id
    subnet_id = aws_subnet.eks_vpc_subnet_1.id    
  
}

resource "aws_route_table_association" "eks_vpc_route_table_association_sb2" {

    route_table_id = aws_route_table.eks_vpc_route_table.id
    subnet_id = aws_subnet.eks_vpc_subnet_2.id    
  
}

resource "aws_security_group" "eks_vpc_sg" {
    vpc_id = aws_vpc.eks_vpc.id
    ingress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = "0.0.0.0/0"
    }
  egress {
     from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = "0.0.0.0/0"
  }

}



