/******************************************
    VPC configuration
 *****************************************/
resource "aws_vpc" "vpc" {
  cidr_block           = local.vpc.cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = local.vpc.tags
}

/******************************************
    Subnet configuration
 *****************************************/
# create internal subnetwork
resource "aws_subnet" "internal_subnet" {
  vpc_id            = aws_vpc.vpc.id
  count             = local.num_subnets
  cidr_block        = element(local.internal_subnet.cidr_block, count.index)
  availability_zone = element(local.internal_subnet.availability_zone, count.index)
  tags              = local.internal_subnet.tags

  depends_on = [
    aws_vpc.vpc
  ]
}

# create external subnetwork
resource "aws_subnet" "external_subnet" {
  vpc_id            = aws_vpc.vpc.id
  count             = local.num_subnets
  cidr_block        = element(local.external_subnet.cidr_block, count.index)
  availability_zone = element(local.external_subnet.availability_zone, count.index)
  tags              = local.external_subnet.tags

  depends_on = [
    aws_vpc.vpc
  ]
}

# create internet GW
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags   = local.igw.tags

  depends_on = [
    aws_vpc.vpc
  ]
}

# create elastic IP
resource "aws_eip" "eip" {
  count = local.num_subnets

  depends_on = [
    aws_subnet.external_subnet
  ]
}

# create NAT GW
resource "aws_nat_gateway" "ngw" {
  count         = local.ngw.count
  allocation_id = element(local.ngw.allocation_id, count.index)
  subnet_id     = element(local.ngw.subnet_id, count.index)

  depends_on = [
    aws_subnet.external_subnet
  ]
}

# create internal route table
resource "aws_route_table" "internal_rt" {
  vpc_id = aws_vpc.vpc.id
  count  = local.internal_rt.count
  route {
    cidr_block     = local.internal_rt.route.cidr_block
    nat_gateway_id = element(local.internal_rt.route.nat_gateway_id, count.index)
  }
  tags = local.internal_rt.tags

  depends_on = [
    aws_nat_gateway.ngw,
    aws_internet_gateway.igw
  ]

}

resource "aws_route_table" "external_rt" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = local.external_rt.route.cidr_block
    gateway_id = local.external_rt.route.gateway_id
  }
  tags = local.external_rt.tags

  depends_on = [
    aws_nat_gateway.ngw,
    aws_internet_gateway.igw
  ]

}

resource "aws_route_table_association" "internal_rta" {
  count          = local.internal_rta.count
  subnet_id      = element(local.internal_rta.subnet_id, count.index)
  route_table_id = element(local.internal_rta.route_table_id, count.index)

  depends_on = [
    aws_route_table.internal_rt,
    aws_route_table.external_rt,
  ]
}

resource "aws_route_table_association" "external_rta" {
  count          = local.external_rta.count
  subnet_id      = element(local.external_rta.subnet_id, count.index)
  route_table_id = local.external_rta.route_table_id

  depends_on = [
    aws_route_table.internal_rt,
    aws_route_table.external_rt,
  ]
}

