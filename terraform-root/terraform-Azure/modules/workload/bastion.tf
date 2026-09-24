resource "tls_private_key" "bastion" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_sensitive_file" "bastion_private_key" {
  content         = tls_private_key.bastion.private_key_pem
  filename        = "${path.root}/bastion_key.pem"
  file_permission = "0600"
}

resource "azurerm_public_ip" "bastion" {
  name                = "${local.bastion.name}-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = local.common_tags
}

resource "azurerm_network_security_group" "bastion" {
  name                = "${local.bastion.name}-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "AllowSSHFromAdminCidrs"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefixes    = var.bastion_allowed_cidrs
    destination_address_prefix = "*"
  }

  tags = local.common_tags
}

resource "azurerm_network_interface" "bastion" {
  name                = "${local.bastion.name}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "primary"
    subnet_id                     = var.public_subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.bastion.id
  }

  tags = local.common_tags
}

resource "azurerm_network_interface_security_group_association" "bastion" {
  network_interface_id      = azurerm_network_interface.bastion.id
  network_security_group_id = azurerm_network_security_group.bastion.id
}

resource "azurerm_linux_virtual_machine" "bastion" {
  name                = local.bastion.name
  location            = var.location
  resource_group_name = var.resource_group_name
  size                = local.bastion.vm_size
  admin_username      = local.bastion.admin_username
  network_interface_ids = [
    azurerm_network_interface.bastion.id,
  ]

  disable_password_authentication = true

  admin_ssh_key {
    username   = local.bastion.admin_username
    public_key = tls_private_key.bastion.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  custom_data = base64encode(<<-CLOUD_INIT
    #cloud-config
    package_update: true
    packages:
      - mysql-client
  CLOUD_INIT
  )

  tags = merge(local.common_tags, {
    Name = local.bastion.name
    Role = "bastion"
  })
}
