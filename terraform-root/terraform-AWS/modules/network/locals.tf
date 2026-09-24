locals {
  namespace = var.namespace

  vpc = {
    name                 = "main"
    cidr_block           = "172.31.0.0/16"
    enable_dns_support   = true
    enable_dns_hostnames = true
  }

  subnet_public = [
    {
      name                    = "public-a"
      availability_zone       = "ap-northeast-2a"
      cidr_block              = "172.31.0.0/24"
      map_public_ip_on_launch = true
    },
    {
      name                    = "public-c"
      availability_zone       = "ap-northeast-2c"
      cidr_block              = "172.31.2.0/24"
      map_public_ip_on_launch = true
    }
  ]

  subnet_private = [
    {
      name                    = "private-a"
      availability_zone       = "ap-northeast-2a"
      cidr_block              = "172.31.4.0/22"
      map_public_ip_on_launch = false
    },
    {
      name                    = "private-c"
      availability_zone       = "ap-northeast-2c"
      cidr_block              = "172.31.8.0/22"
      map_public_ip_on_launch = false
    },
    {
      name                    = "private-a-db"
      availability_zone       = "ap-northeast-2a"
      cidr_block              = "172.31.16.0/22"
      map_public_ip_on_launch = false
    },
    {
      name                    = "private-c-db"
      availability_zone       = "ap-northeast-2c"
      cidr_block              = "172.31.32.0/22"
      map_public_ip_on_launch = false
    },
    {
      name                    = "private-a-dms"
      availability_zone       = "ap-northeast-2a"
      cidr_block              = "172.31.64.0/22"
      map_public_ip_on_launch = false
    },
    {
      name                    = "private-c-dms"
      availability_zone       = "ap-northeast-2c"
      cidr_block              = "172.31.128.0/22"
      map_public_ip_on_launch = false
    }
  ]

  natgw = {
    name = "main"
  }

  azure_vpn_gateway_public_ip            = var.azure_vpn_gateway_public_ip
  azure_ip_cidr_block                    = var.azure_ip_cidr_block
  azure_private_dns_resolver_inbound_ips = var.azure_private_dns_resolver_inbound_ips

  azure_dns_forwarding = {
    enabled = length(local.azure_private_dns_resolver_inbound_ips) > 0
    domains = [
      "mysql.database.azure.com",
      "privatelink.mysql.database.azure.com"
    ]
  }
}
