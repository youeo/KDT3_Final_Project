resource "azurerm_subnet" "public_0" {
  name                 = "${local.namespace}-subnet-${local.subnet_public[0].name}"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [local.subnet_public[0].address_cidr]

  timeouts {
    create = "60m"
    update = "60m"
    delete = "60m"
    read   = "60m"
  }
}

resource "azurerm_subnet" "public_1" {
  name                 = "${local.namespace}-subnet-${local.subnet_public[1].name}"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [local.subnet_public[1].address_cidr]

  timeouts {
    create = "60m"
    update = "60m"
    delete = "60m"
    read   = "60m"
  }

  depends_on = [azurerm_subnet.public_0]
}

resource "azurerm_subnet" "private_0" {
  name                 = "${local.namespace}-subnet-${local.subnet_private[0].name}"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [local.subnet_private[0].address_cidr]

  timeouts {
    create = "60m"
    update = "60m"
    delete = "60m"
    read   = "60m"
  }
}

resource "azurerm_subnet" "private_1" {
  name                 = "${local.namespace}-subnet-${local.subnet_private[1].name}"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [local.subnet_private[1].address_cidr]

  timeouts {
    create = "60m"
    update = "60m"
    delete = "60m"
    read   = "60m"
  }
}

resource "azurerm_subnet" "database" {
  name                 = "${local.namespace}-subnet-${local.subnet_database.name}"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [local.subnet_database.address_cidr]

  delegation {
    name = "mysql-flexible-server-delegation"

    service_delegation {
      name = "Microsoft.DBforMySQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }

  timeouts {
    create = "60m"
    update = "60m"
    delete = "60m"
    read   = "60m"
  }
}

resource "azurerm_subnet" "dns_resolver_inbound" {
  name                 = "${local.namespace}-subnet-${local.subnet_dns_resolver.name}"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [local.subnet_dns_resolver.address_cidr]

  delegation {
    name = "dns-resolver-delegation"

    service_delegation {
      name = "Microsoft.Network/dnsResolvers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }

  timeouts {
    create = "60m"
    update = "60m"
    delete = "60m"
    read   = "60m"
  }
}

resource "azurerm_subnet" "dns_resolver_outbound" {
  name                 = "${local.namespace}-subnet-${local.subnet_dns_resolver_outbound.name}"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [local.subnet_dns_resolver_outbound.address_cidr]

  delegation {
    name = "dns-resolver-outbound-delegation"

    service_delegation {
      name = "Microsoft.Network/dnsResolvers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }

  timeouts {
    create = "60m"
    update = "60m"
    delete = "60m"
    read   = "60m"
  }
}

resource "azurerm_subnet" "gateway" {
  name                 = local.gateway_subnet.name
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [local.gateway_subnet.address_cidr]

  timeouts {
    create = "60m"
    update = "60m"
    delete = "60m"
    read   = "60m"
  }
}

# Public용 NSG: 외부(인터넷) 접근 허용 정책
resource "azurerm_network_security_group" "public_nsg" {
  name                = "${local.namespace}-nsg-public"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  security_rule {
    name                       = "AllowWebInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443"]
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Private용 NSG: 외부 접근 차단 (내부 통신만 허용)
resource "azurerm_network_security_group" "private_nsg" {
  name                = "${local.namespace}-nsg-private"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  # 추가 규칙이 없으면 기본적으로 모든 외부 Inbound는 차단됨
}

# DNS Resolver 전용
resource "azurerm_network_security_group" "dns_nsg" {
  name                = "${local.namespace}-nsg-dns"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  security_rule {
    name                       = "AllowDNS"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "53"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }
}

# DNS Resolver 서브넷 연결
resource "azurerm_subnet_network_security_group_association" "dns_in_assoc" {
  subnet_id                 = azurerm_subnet.dns_resolver_inbound.id
  network_security_group_id = azurerm_network_security_group.dns_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "dns_out_assoc" {
  subnet_id                 = azurerm_subnet.dns_resolver_outbound.id
  network_security_group_id = azurerm_network_security_group.dns_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "public_assoc_0" {
  subnet_id                 = azurerm_subnet.public_0.id
  network_security_group_id = azurerm_network_security_group.public_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "public_assoc_1" {
  subnet_id                 = azurerm_subnet.public_1.id
  network_security_group_id = azurerm_network_security_group.public_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "private_assoc_0" {
  subnet_id                 = azurerm_subnet.private_0.id
  network_security_group_id = azurerm_network_security_group.private_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "private_assoc_1" {
  subnet_id                 = azurerm_subnet.private_1.id
  network_security_group_id = azurerm_network_security_group.private_nsg.id
}

resource "azurerm_subnet_nat_gateway_association" "private_0" {
  subnet_id      = azurerm_subnet.private_0.id
  nat_gateway_id = azurerm_nat_gateway.this.id
}

resource "azurerm_subnet_nat_gateway_association" "private_1" {
  subnet_id      = azurerm_subnet.private_1.id
  nat_gateway_id = azurerm_nat_gateway.this.id
}