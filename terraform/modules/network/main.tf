data "aws_availability_zones" "available_zones" {}

resource "aws_vpc" "eks_vpc" {
  cidr_block = var.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name    = "${var.project}-vpc"
    project = var.project
  }
}
# Public Subnets
resource "aws_subnet" "eks_public_subnets" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available_zones.names[count.index]
  map_public_ip_on_launch = true
  tags = {
    Name    = "${var.project}-public-subnet-${count.index}"
    project = var.project
    "kubernetes.io/role/elb" = "1"
  }
}

# Private Subnets
resource "aws_subnet" "eks_private_subnets" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.eks_vpc.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available_zones.names[count.index]
  tags = {
    Name    = "${var.project}-private-subnet-${count.index}"
    project = var.project
    "kubernetes.io/role/internal-elb"                  = "1"
  }
}

resource "aws_internet_gateway" "eks_igw" {
  vpc_id = aws_vpc.eks_vpc.id
  tags = {
    Name    = "${var.project}-igw"
    project = var.project
  }
}

# NAT Gateway needs an Elastic IP
resource "aws_eip" "nat_eip" {
  count = length(aws_subnet.eks_public_subnets.*.id)
  lifecycle {
    prevent_destroy = false
  }
  tags = {
    Name    = "${var.project}-nat-eip"
    project = var.project
  }
}

# NAT Gateway configuration for each public subnet
resource "aws_nat_gateway" "nat_gateway" {
  count         = length(aws_subnet.eks_public_subnets.*.id)
  allocation_id = aws_eip.nat_eip[count.index].id
  subnet_id     = aws_subnet.eks_public_subnets[count.index].id

  tags = {
    Name    = "${var.project}-nat-gateway"
    project = var.project
  }
  depends_on = [aws_internet_gateway.eks_igw]
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.eks_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.eks_igw.id
  }
  tags = {
    Name    = "${var.project}-public-route-table"
    project = var.project
  }
}

resource "aws_route_table_association" "public_subnet_association" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = element(aws_subnet.eks_public_subnets.*.id, count.index)
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table" "private_route_table" {
  count = length(aws_subnet.eks_private_subnets.*.id)
  vpc_id = aws_vpc.eks_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway[count.index].id
  }
  tags = {
    Name    = "${var.project}-private-route-table-${count.index}"
    project = var.project
  }
}

resource "aws_route_table_association" "private_subnet_association" {
  count          = length(aws_subnet.eks_private_subnets.*.id)
  subnet_id      = aws_subnet.eks_private_subnets[count.index].id
  route_table_id = aws_route_table.private_route_table[count.index].id
}