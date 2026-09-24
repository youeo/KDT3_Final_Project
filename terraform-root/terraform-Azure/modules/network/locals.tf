locals {
  namespace = var.namespace
  location  = var.location

  common_tags = {
    Environment = "dev"
    Project     = "Project3-MSA"
    ManagedBy   = "Terraform"
  }

  vnet = {
    name          = "main"
    address_space = "10.0.0.0/16"
  }

  subnet_public = [
    {
      name         = "public-a"
      address_cidr = "10.0.1.0/24"
    },
    {
      name         = "public-c"
      address_cidr = "10.0.2.0/24"
    }
  ]

  subnet_private = [
    {
      name         = "private-a"
      address_cidr = "10.0.101.0/24"
    },
    {
      name         = "private-c"
      address_cidr = "10.0.102.0/24"
    },
    {
      name         = "private-db-a"
      address_cidr = "10.0.103.0/24"
    },
    {
      name         = "private-db-c"
      address_cidr = "10.0.104.0/24"
    }
  ]

  subnet_database = {
    name         = "db"
    address_cidr = "10.0.201.0/24"
  }

  subnet_dns_resolver = {
    name         = "dns-resolver"
    address_cidr = "10.0.254.0/28"
  }

  subnet_dns_resolver_outbound = {
    name         = "dns-resolver-outbound"
    address_cidr = "10.0.254.16/28"
  }

  gateway_subnet = {
    name         = "GatewaySubnet"
    address_cidr = "10.0.255.0/27"
  }

  natgw = {
    name = "main"
  }

  vpn_gateway = {
    name = "s2s"
  }

  aws_vpn_tunnels = {
    tunnel-1 = {
      local_network_gateway_name = "local-networ-gw-tunnel-1"
      connection_name            = "vpn-conn"
      gateway_ip_address         = var.tunnel1_ip
      shared_key                 = var.tunnel1_key
    }
    tunnel-2 = {
      local_network_gateway_name = "local-networ-gw-tunnel-2"
      connection_name            = "vpn-conn2"
      gateway_ip_address         = var.tunnel2_ip
      shared_key                 = var.tunnel2_key
    }
  }

  dns_private_resolver = {
    name                   = "main"
    inbound_endpoint_name  = "inbound"
    outbound_endpoint_name = "outbound"
  }
}
