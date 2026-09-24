resource "azurerm_private_dns_resolver" "this" {
  name                = "${local.namespace}-pdnsr-${local.dns_private_resolver.name}"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  virtual_network_id  = azurerm_virtual_network.this.id

  #Vnet 생성이 완료된 후에 DNS Resolver 생성이 필요하므로 depends_on 추가
  depends_on = [
    azurerm_virtual_network.this,
    azurerm_subnet.dns_resolver_inbound,
    azurerm_subnet.dns_resolver_outbound
  ]

  tags = local.common_tags
}

resource "azurerm_private_dns_resolver_inbound_endpoint" "this" {
  name                    = "${local.namespace}-pdnsr-${local.dns_private_resolver.inbound_endpoint_name}"
  private_dns_resolver_id = azurerm_private_dns_resolver.this.id
  location                = azurerm_resource_group.this.location

  ip_configurations {
    private_ip_allocation_method = "Dynamic"
    subnet_id                    = azurerm_subnet.dns_resolver_inbound.id
  }

  tags = local.common_tags
}

resource "azurerm_private_dns_resolver_outbound_endpoint" "this" {
  name                    = "${local.namespace}-pdnsr-${local.dns_private_resolver.outbound_endpoint_name}"
  private_dns_resolver_id = azurerm_private_dns_resolver.this.id
  location                = azurerm_resource_group.this.location
  subnet_id               = azurerm_subnet.dns_resolver_outbound.id

  tags = local.common_tags
}
