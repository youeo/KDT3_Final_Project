# 고객 게이트웨이 (Azure의 공인 IP 등록)
resource "aws_customer_gateway" "azure_cgw" {
  bgp_asn    = 65000                             # Azure와 맞출 BGP ASN
  ip_address = local.azure_vpn_gateway_public_ip # Azure VPN Gateway의 IP
  type       = "ipsec.1"

  tags = {
    Name = "${local.namespace}-cgw"
  }
}

# 가상 프라이빗 게이트웨이 (VPC에 연결)
resource "aws_vpn_gateway" "vpn_gw" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${local.namespace}-vgw"
  }
}

# VPN 연결 생성
resource "aws_vpn_connection" "main" {
  vpn_gateway_id      = aws_vpn_gateway.vpn_gw.id
  customer_gateway_id = aws_customer_gateway.azure_cgw.id
  type                = "ipsec.1"
  static_routes_only  = true

  tags = {
    Name = "${local.namespace}-vpn-connection"
  }
}

# Azure 사설망 대역을 정적 라우팅으로 추가
resource "aws_vpn_connection_route" "azure_route" {
  destination_cidr_block = local.azure_ip_cidr_block
  vpn_connection_id      = aws_vpn_connection.main.id
}