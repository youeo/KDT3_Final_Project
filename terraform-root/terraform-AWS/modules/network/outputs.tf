output "vpc" {
  value = {
    (local.vpc.name) = {
      id = aws_vpc.this.id
    }
  }
}

output "subnet" {
  value = {
    (local.subnet_public[0].name) = {
      id         = aws_subnet.public_0.id
      cidr_block = aws_subnet.public_0.cidr_block
    }
    (local.subnet_public[1].name) = {
      id         = aws_subnet.public_1.id
      cidr_block = aws_subnet.public_1.cidr_block
    }
    (local.subnet_private[0].name) = {
      id         = aws_subnet.private_0.id
      cidr_block = aws_subnet.private_0.cidr_block
    }
    (local.subnet_private[1].name) = {
      id         = aws_subnet.private_1.id
      cidr_block = aws_subnet.private_1.cidr_block
    }
    (local.subnet_private[2].name) = {
      id         = aws_subnet.private_2.id
      cidr_block = aws_subnet.private_2.cidr_block
    }
    (local.subnet_private[3].name) = {
      id         = aws_subnet.private_3.id
      cidr_block = aws_subnet.private_3.cidr_block
    }
    (local.subnet_private[4].name) = {
      id         = aws_subnet.private_4.id
      cidr_block = aws_subnet.private_4.cidr_block
    }
    (local.subnet_private[5].name) = {
      id         = aws_subnet.private_5.id
      cidr_block = aws_subnet.private_5.cidr_block
    }
  }
}

output "vpn_tunnel1_outside_ip" {
  value = aws_vpn_connection.main.tunnel1_address
}

output "vpn_tunnel2_outside_ip" {
  value = aws_vpn_connection.main.tunnel2_address
}

output "vpn_tunnel1_preshared_key" {
  value     = aws_vpn_connection.main.tunnel1_preshared_key
  sensitive = true # 보안을 위해 민감 정보로 마킹
}

output "vpn_tunnel2_preshared_key" {
  value     = aws_vpn_connection.main.tunnel2_preshared_key
  sensitive = true # 보안을 위해 민감 정보로 마킹
}
