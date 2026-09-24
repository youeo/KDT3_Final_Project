output "resource_group_name" {
  value = azurerm_resource_group.this.name
}

output "location" {
  value = azurerm_resource_group.this.location
}

output "vnet" {
  value = {
    (local.vnet.name) = {
      id   = azurerm_virtual_network.this.id
      cidr = local.vnet.address_space
      name = azurerm_virtual_network.this.name
    }
  }
}

output "subnet" {
  value = {
    (local.subnet_public[0].name) = {
      id         = azurerm_subnet.public_0.id
      cidr_block = azurerm_subnet.public_0.address_prefixes[0]
    }
    (local.subnet_public[1].name) = {
      id         = azurerm_subnet.public_1.id
      cidr_block = azurerm_subnet.public_1.address_prefixes[0]
    }
    (local.subnet_private[0].name) = {
      id         = azurerm_subnet.private_0.id
      cidr_block = azurerm_subnet.private_0.address_prefixes[0]
    }
    (local.subnet_private[1].name) = {
      id         = azurerm_subnet.private_1.id
      cidr_block = azurerm_subnet.private_1.address_prefixes[0]
    }
    (local.subnet_database.name) = {
      id         = azurerm_subnet.database.id
      cidr_block = azurerm_subnet.database.address_prefixes[0]
    }
    (local.subnet_dns_resolver.name) = {
      id         = azurerm_subnet.dns_resolver_inbound.id
      cidr_block = azurerm_subnet.dns_resolver_inbound.address_prefixes[0]
    }
    (local.subnet_dns_resolver_outbound.name) = {
      id         = azurerm_subnet.dns_resolver_outbound.id
      cidr_block = azurerm_subnet.dns_resolver_outbound.address_prefixes[0]
    }
    (local.gateway_subnet.name) = {
      id         = azurerm_subnet.gateway.id
      cidr_block = azurerm_subnet.gateway.address_prefixes[0]
    }
  }
}

output "vpn_gateway" {
  value = {
    id                = azurerm_virtual_network_gateway.vpn.id
    name              = azurerm_virtual_network_gateway.vpn.name
    public_ip_address = azurerm_public_ip.vpn_gateway.ip_address
  }
}

output "dns_private_resolver" {
  value = {
    id                     = azurerm_private_dns_resolver.this.id
    name                   = azurerm_private_dns_resolver.this.name
    inbound_endpoint_id    = azurerm_private_dns_resolver_inbound_endpoint.this.id
    inbound_endpoint_name  = azurerm_private_dns_resolver_inbound_endpoint.this.name
    inbound_ip_addresses   = azurerm_private_dns_resolver_inbound_endpoint.this.ip_configurations[*].private_ip_address
    outbound_endpoint_id   = azurerm_private_dns_resolver_outbound_endpoint.this.id
    outbound_endpoint_name = azurerm_private_dns_resolver_outbound_endpoint.this.name
  }
}

output "aws_vpn" {
  value = {
    local_network_gateways = {
      for key, gateway in azurerm_local_network_gateway.aws : key => {
        id                   = gateway.id
        name                 = gateway.name
        gateway_ip_address   = gateway.gateway_address
        remote_address_space = gateway.address_space
      }
    }
    connections = {
      for key, connection in azurerm_virtual_network_gateway_connection.aws : key => {
        id   = connection.id
        name = connection.name
      }
    }
  }
}
