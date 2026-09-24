# public subnet 0
resource "aws_subnet" "public_0" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = local.subnet_public[0].cidr_block
  availability_zone       = local.subnet_public[0].availability_zone
  map_public_ip_on_launch = local.subnet_public[0].map_public_ip_on_launch

  tags = {
    Name                     = "${local.namespace}-subnet-${local.subnet_public[0].name}"
    "kubernetes.io/role/elb" = "1"
  }
}

# public subnet 1
resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = local.subnet_public[1].cidr_block
  availability_zone       = local.subnet_public[1].availability_zone
  map_public_ip_on_launch = local.subnet_public[1].map_public_ip_on_launch

  tags = {
    Name                     = "${local.namespace}-subnet-${local.subnet_public[1].name}"
    "kubernetes.io/role/elb" = "1"
  }
}

# private subnet_0
resource "aws_subnet" "private_0" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = local.subnet_private[0].cidr_block
  availability_zone       = local.subnet_private[0].availability_zone
  map_public_ip_on_launch = local.subnet_private[0].map_public_ip_on_launch

  tags = {
    Name = "${local.namespace}-subnet-${local.subnet_private[0].name}"
  }
}

# private subnet_1
resource "aws_subnet" "private_1" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = local.subnet_private[1].cidr_block
  availability_zone       = local.subnet_private[1].availability_zone
  map_public_ip_on_launch = local.subnet_private[1].map_public_ip_on_launch

  tags = {
    Name = "${local.namespace}-subnet-${local.subnet_private[1].name}"
  }
}

# private subnet_2
resource "aws_subnet" "private_2" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = local.subnet_private[2].cidr_block
  availability_zone       = local.subnet_private[2].availability_zone
  map_public_ip_on_launch = local.subnet_private[2].map_public_ip_on_launch

  tags = {
    Name = "${local.namespace}-subnet-${local.subnet_private[2].name}"
  }
}

# private subnet_3
resource "aws_subnet" "private_3" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = local.subnet_private[3].cidr_block
  availability_zone       = local.subnet_private[3].availability_zone
  map_public_ip_on_launch = local.subnet_private[3].map_public_ip_on_launch

  tags = {
    Name = "${local.namespace}-subnet-${local.subnet_private[3].name}"
  }
}

# private subnet_4
resource "aws_subnet" "private_4" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = local.subnet_private[4].cidr_block
  availability_zone       = local.subnet_private[4].availability_zone
  map_public_ip_on_launch = local.subnet_private[4].map_public_ip_on_launch

  tags = {
    Name = "${local.namespace}-subnet-${local.subnet_private[4].name}"
  }
}

# private subnet_5
resource "aws_subnet" "private_5" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = local.subnet_private[5].cidr_block
  availability_zone       = local.subnet_private[5].availability_zone
  map_public_ip_on_launch = local.subnet_private[5].map_public_ip_on_launch

  tags = {
    Name = "${local.namespace}-subnet-${local.subnet_private[5].name}"
  }
}

resource "aws_route_table" "public_0" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  # azure로의 경로
  route {
    cidr_block = local.azure_ip_cidr_block
    gateway_id = aws_vpn_gateway.vpn_gw.id
  }

  tags = {
    Name = "${local.namespace}-rtb-${local.subnet_public[0].name}"
  }
}

resource "aws_route_table" "public_1" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  route {
    cidr_block = local.azure_ip_cidr_block
    gateway_id = aws_vpn_gateway.vpn_gw.id
  }

  tags = {
    Name = "${local.namespace}-rtb-${local.subnet_public[1].name}"
  }
}

resource "aws_route_table" "private_0" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this.id
  }

  tags = {
    Name = "${local.namespace}-rtb-${local.subnet_private[0].name}"
  }
}

resource "aws_route_table" "private_1" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this.id
  }

  tags = {
    Name = "${local.namespace}-rtb-${local.subnet_private[1].name}"
  }
}

resource "aws_route_table" "private_db" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this.id
  }

  tags = {
    Name = "${local.namespace}-rtb-private-db"
  }
}

resource "aws_route_table" "private_dms" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this.id
  }

  route {
    cidr_block = local.azure_ip_cidr_block
    gateway_id = aws_vpn_gateway.vpn_gw.id
  }

  tags = {
    Name = "${local.namespace}-rtb-dms"
  }
}

resource "aws_route_table_association" "public_0" {
  subnet_id      = aws_subnet.public_0.id
  route_table_id = aws_route_table.public_0.id
}

resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public_1.id
}

resource "aws_route_table_association" "private_0" {
  subnet_id      = aws_subnet.private_0.id
  route_table_id = aws_route_table.private_0.id
}

resource "aws_route_table_association" "private_1" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private_1.id
}

resource "aws_route_table_association" "private_2" {
  subnet_id      = aws_subnet.private_2.id
  route_table_id = aws_route_table.private_db.id
}

resource "aws_route_table_association" "private_3" {
  subnet_id      = aws_subnet.private_3.id
  route_table_id = aws_route_table.private_db.id
}

resource "aws_route_table_association" "private_4" {
  subnet_id      = aws_subnet.private_4.id
  route_table_id = aws_route_table.private_dms.id
}

resource "aws_route_table_association" "private_5" {
  subnet_id      = aws_subnet.private_5.id
  route_table_id = aws_route_table.private_dms.id
}
