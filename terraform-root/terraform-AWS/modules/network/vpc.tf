resource "aws_vpc" "this" {
  cidr_block           = local.vpc.cidr_block
  enable_dns_support   = local.vpc.enable_dns_support
  enable_dns_hostnames = local.vpc.enable_dns_hostnames

  tags = {
    Name = "${local.namespace}-vpc-${local.vpc.name}"
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${local.namespace}-igw"
  }
}

resource "aws_eip" "this" {
  domain = "vpc"

  tags = {
    Name = "${local.namespace}-eip-natgw-${local.natgw.name}"
  }
}

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.this.id
  subnet_id     = aws_subnet.public_0.id

  tags = {
    Name = "${local.namespace}-natgw-${local.natgw.name}"
  }
}