resource "aws_security_group" "resolver_outbound" {
  count = local.azure_dns_forwarding.enabled ? 1 : 0

  name        = "${local.namespace}-sg-r53-resolver-outbound"
  description = "Allow Route 53 Resolver outbound DNS queries to Azure DNS Private Resolver"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "DNS over TCP from VPC"
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = [local.vpc.cidr_block]
  }

  ingress {
    description = "DNS over UDP from VPC"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = [local.vpc.cidr_block]
  }

  egress {
    description = "DNS over TCP to Azure resolver"
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = [for ip in local.azure_private_dns_resolver_inbound_ips : "${ip}/32"]
  }

  egress {
    description = "DNS over UDP to Azure resolver"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = [for ip in local.azure_private_dns_resolver_inbound_ips : "${ip}/32"]
  }

  tags = {
    Name = "${local.namespace}-sg-r53-resolver-outbound"
  }
}

resource "aws_route53_resolver_endpoint" "azure_outbound" {
  count = local.azure_dns_forwarding.enabled ? 1 : 0

  name      = "${local.namespace}-r53-outbound-azure"
  direction = "OUTBOUND"

  security_group_ids = [
    aws_security_group.resolver_outbound[0].id
  ]

  ip_address {
    subnet_id = aws_subnet.private_4.id
  }
  ip_address {
    subnet_id = aws_subnet.private_5.id
  }

  tags = {
    Name = "${local.namespace}-r53-outbound-azure"
  }
}

resource "aws_route53_resolver_rule" "azure_mysql" {
  for_each = local.azure_dns_forwarding.enabled ? toset(local.azure_dns_forwarding.domains) : toset([])

  domain_name          = each.value
  name                 = "${local.namespace}-${replace(each.value, ".", "-")}"
  rule_type            = "FORWARD"
  resolver_endpoint_id = aws_route53_resolver_endpoint.azure_outbound[0].id

  dynamic "target_ip" {
    for_each = local.azure_private_dns_resolver_inbound_ips

    content {
      ip = target_ip.value
    }
  }

  tags = {
    Name = "${local.namespace}-${replace(each.value, ".", "-")}"
  }
}

resource "aws_route53_resolver_rule_association" "azure_mysql" {
  for_each = aws_route53_resolver_rule.azure_mysql

  name             = each.value.name
  resolver_rule_id = each.value.id
  vpc_id           = aws_vpc.this.id
}