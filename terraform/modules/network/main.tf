data "aws_availability_zones" "available_zones" {}

resource "aws_vpc" "eks_vpc" {
  cidr_block = var.cidr_block
  tags = {
    Name    = "${var.project}-vpc"
    project = var.project
  }
}

resource "aws_subnet" "eks_subnets" {
  count                   = var.subnet_count
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = "10.0.${count.index}.0/24"
  availability_zone       = data.aws_availability_zones.available_zones.names[count.index]
  map_public_ip_on_launch = true
  tags = {
    Name    = "${var.project}-subnet-${count.index}"
    project = var.project
  }
}

resource "aws_internet_gateway" "eks_igw" {
  vpc_id = aws_vpc.eks_vpc.id
  tags = {
    Name    = "${var.project}-igw"
    project = var.project
  }
}

resource "aws_route_table" "eks_route_table" {
  vpc_id = aws_vpc.eks_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.eks_igw.id
  }
  tags = {
    Name    = "${var.project}-route-table"
    project = var.project
  }
}

resource "aws_route_table_association" "subnet_association" {
  count          = var.subnet_count
  subnet_id      = aws_subnet.eks_subnets[count.index].id
  route_table_id = aws_route_table.eks_route_table.id

}