resource "azurerm_resource_group" "this" {
  name     = "${local.namespace}-rg"
  location = local.location

  tags = local.common_tags

  lifecycle {
    precondition {
      condition     = !startswith(local.namespace, "tf-core-ej-")
      error_message = "Refusing to create legacy tf-core-ej Azure resource groups from this Terraform stack."
    }
  }
}

resource "azurerm_virtual_network" "this" {
  name                = "${local.namespace}-vnet-${local.vnet.name}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = [local.vnet.address_space]

  tags = local.common_tags
}

resource "azurerm_public_ip" "nat" {
  name                = "${local.namespace}-pip-natgw-${local.natgw.name}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = local.common_tags
}

resource "azurerm_nat_gateway" "this" {
  name                = "${local.namespace}-natgw-${local.natgw.name}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  sku_name            = "Standard"

  depends_on = [azurerm_subnet.private_0, azurerm_subnet.private_1]

  tags = local.common_tags
}

resource "azurerm_nat_gateway_public_ip_association" "this" {
  nat_gateway_id       = azurerm_nat_gateway.this.id
  public_ip_address_id = azurerm_public_ip.nat.id
}
