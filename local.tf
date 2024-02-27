locals {
  project    = "backstage-eks-test"
  aws_region = "ap-northeast-1"

  base_tags = {
    terraform = "true"
    eks       = "backstage-eks"
  }

  /******************************************
    VPC configuration
   *****************************************/
  vpc = {
    cidr_block = "192.168.0.0/16"
    tags       = merge(local.base_tags, tomap({"Name"="${local.project}-vpc"))
  }

  /******************************************
    Subnet configuration
   *****************************************/
  num_subnets = "3"

  availability_zone = [
    "ap-northeast-1a",
    "ap-northeast-1c",
    "ap-northeast-1d",
  ]

  internal_subnet = {
    cidr_block = [
      "192.168.0.0/24",
      "192.168.1.0/24",
      "192.168.2.0/24",
    ]
    availability_zone = local.availability_zone
    tags              = merge(local.base_tags, tomap("Name"="${local.project}-subnet-internal"), tomap("kubernetes.io/cluster/${local.project}"="shared"))
  }

  external_subnet = {
    cidr_block = [
      "192.168.3.0/24",
      "192.168.4.0/24",
      "192.168.5.0/24",
    ]
    availability_zone = local.availability_zone
    tags              = merge(local.base_tags, tomap("Name"="${local.project}-subnet-external"), tomap("kubernetes.io/cluster/${local.project}"="shared"))
  }

  /******************************************
    Internet GW configuration
   *****************************************/
  igw = {
    tags = merge(local.base_tags, tomap("Name"="${local.project}-inetrnet-gw"))
  }


  /******************************************
    NAT GW configuration
   *****************************************/
  ngw = {
    count         = local.num_subnets
    allocation_id = aws_eip.eip[*].id
    subnet_id     = aws_subnet.external_subnet[*].id
  }

  /******************************************
    Route table configuration
   *****************************************/
  internal_rt = {
    count = local.num_subnets
    route = {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.ngw[*].id
    }
    tags = merge(local.base_tags, tomap("Name"="${local.project}-internal-routetable"))
  }

  external_rt = {
    count = "1"
    route = {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.igw.id
    }
    tags = merge(local.base_tags, tomap("Name"="${local.project}-external-routetable"))
  }

  /******************************************
    Route table association configuration
   *****************************************/
  internal_rta = {
    count          = local.num_subnets
    subnet_id      = aws_subnet.internal_subnet[*].id
    route_table_id = aws_route_table.internal_rt[*].id
  }

  external_rta = {
    count          = local.num_subnets
    subnet_id      = aws_subnet.external_subnet[*].id
    route_table_id = aws_route_table.external_rt.id
  }
}
