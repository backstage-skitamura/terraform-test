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
    tags       = merge(local.base_tags, map("Name", "${local.project}-vpc"))
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
    tags              = merge(local.base_tags, map("Name", "${local.project}-subnet-internal"), map("kubernetes.io/cluster/${local.project}", "shared"))
  }

  external_subnet = {
    cidr_block = [
      "192.168.3.0/24",
      "192.168.4.0/24",
      "192.168.5.0/24",
    ]
    availability_zone = local.availability_zone
    tags              = merge(local.base_tags, map("Name", "${local.project}-subnet-external"), map("kubernetes.io/cluster/${local.project}", "shared"))
  }

  /******************************************
    Internet GW configuration
   *****************************************/
  igw = {
    tags = merge(local.base_tags, map("Name", "${local.project}-inetrnet-gw"))
  }


  /******************************************
    NAT GW configuration
   *****************************************/
  ngw = {
    count         = local.num_subnets
    allocation_id = module.eip.eip[*].id
    subnet_id     = module.external_subnet.subnet[*].id
  }

  /******************************************
    Route table configuration
   *****************************************/
  internal_rt = {
    count = local.num_subnets
    route = {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = module.ngw.ngw[*].id
    }
    tags = merge(local.base_tags, map("Name", "${local.project}-internal-routetable"))
  }

  external_rt = {
    count = "1"
    route = {
      cidr_block = "0.0.0.0/0"
      gateway_id = module.igw.igw.id
    }
    tags = merge(local.base_tags, map("Name", "${local.project}-external-routetable"))
  }

  /******************************************
    Route table association configuration
   *****************************************/
  internal_rta = {
    count          = local.num_subnets
    subnet_id      = module.internal_subnet.subnet[*].id
    route_table_id = module.rt.internal_rt[*].id
  }

  external_rta = {
    count          = local.num_subnets
    subnet_id      = module.external_subnet.subnet[*].id
    route_table_id = module.rt.external_rt.id
  }
}
