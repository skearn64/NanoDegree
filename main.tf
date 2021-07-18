provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "skproject1-rg" {
  name     = "${var.prefix}-resources"
  location = var.location
}

resource "azurerm_virtual_network" "skproject1-rg" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/22"]
  location            = azurerm_resource_group.skproject1-rg.location
  resource_group_name = azurerm_resource_group.skproject1-rg.name
}

resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.skproject1-rg.name
  virtual_network_name = azurerm_virtual_network.skproject1-rg.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_interface" "skproject1-rg" {
  count               = var.counter
  name                = "${var.prefix}-nic${count.index}"
  resource_group_name = azurerm_resource_group.skproject1-rg.name
  location            = azurerm_resource_group.skproject1-rg.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_public_ip" "skproject1-rg" {
  name                = "acceptanceTestPublicIp"
  resource_group_name = azurerm_resource_group.skproject1-rg.name
  location            = azurerm_resource_group.skproject1-rg.location
  allocation_method   = "Static"

  tags = {
    environment = "Udacity Project 1"
  }
}

resource "azurerm_lb" "skproject1-rg" {
  name                = "Project1LoadBalancer"
  location            = azurerm_resource_group.skproject1-rg.location
  resource_group_name = azurerm_resource_group.skproject1-rg.name

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.skproject1-rg.id
  }

  tags = {
     environment = "Web Server LB"
  }
}

resource "azurerm_lb_backend_address_pool" "skproject1-rg" {
  loadbalancer_id = azurerm_lb.skproject1-rg.id
  name            = "${var.prefix}-BackEndAddressPool"
}

resource "azurerm_network_interface_backend_address_pool_association" "skproject1-rg" {
  count                   = var.counter
  network_interface_id    = azurerm_network_interface.skproject1-rg[count.index].id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.skproject1-rg.id
}

resource "azurerm_availability_set" "skproject1-rg" {
  name                        = "project1-aset"
  location                    = azurerm_resource_group.skproject1-rg.location
  resource_group_name         = azurerm_resource_group.skproject1-rg.name
  platform_fault_domain_count = 2

  tags = {
    environment = "Production Web Server"
  }
}

resource "azurerm_network_security_group" "skproject1-rg" {
  name                = "project1WebServerDeployment"
  location            = azurerm_resource_group.skproject1-rg.location
  resource_group_name = azurerm_resource_group.skproject1-rg.name

  security_rule{
    name                        = "allowVNet-In"
    priority                    = 100
    direction                   = "Inbound"
    access                      = "Allow"
    protocol                    = "*"
    source_port_range           = "*"
    destination_port_range      = "*"
    source_address_prefix       = "VirtualNetwork"
    destination_address_prefix  = "VirtualNetwork"
  }

  security_rule{
    name                        = "allowVNet-Out"
    priority                    = 150
    direction                   = "Outbound"
    access                      = "Allow"
    protocol                    = "*"
    source_port_range           = "*"
    destination_port_range      = "*"
    source_address_prefix       = "VirtualNetwork"
    destination_address_prefix  = "VirtualNetwork"
  }

  security_rule{
    name                        = "allowAzureLBtoVNet-In"
    priority                    = 160
    direction                   = "Inbound"
    access                      = "Allow"
    protocol                    = "*"
    source_port_range           = "*"
    destination_port_range      = "*"
    source_address_prefix       = "AzureLoadBalancer"
    destination_address_prefix  = "VirtualNetwork"
  }
  security_rule {
    name                       = "Deny Inbound Internet Traffic"
    priority                   = 250
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "Production Web Server"
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "skproject1-rg" {
    count                     = var.counter
    network_interface_id      = azurerm_network_interface.skproject1-rg[count.index].id
    network_security_group_id = azurerm_network_security_group.skproject1-rg.id
}

data "azurerm_image" "packer-webserver-image" {
  name                = "skProject1PackerImage"
  resource_group_name = "skproject1-rg"
}

resource "azurerm_linux_virtual_machine" "skproject1-rg" {
  count                           = var.counter
  name                            = "${var.prefix}-vm${count.index}"
  resource_group_name             = azurerm_resource_group.skproject1-rg.name
  location                        = azurerm_resource_group.skproject1-rg.location
  size                            = "Standard_D2s_v3"
  admin_username                  = "${var.username}"
  admin_password                  = "${var.password}"
  availability_set_id             = azurerm_availability_set.skproject1-rg.id
  disable_password_authentication = false
  network_interface_ids = [
    azurerm_network_interface.skproject1-rg[count.index].id,
  ]

  source_image_id = data.azurerm_image.packer-webserver-image.id

  os_disk {
    name                 = "${var.prefix}-osdisk-${count.index}"
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  tags = {
    environment = "Linux Production Web Server"
  }
}

resource "azurerm_managed_disk" "datadisk" {
  count                = var.counter
  name                 = "${var.prefix}-vm${count.index}-datadisk"
  location             = azurerm_resource_group.skproject1-rg.location
  resource_group_name  = azurerm_resource_group.skproject1-rg.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "1"

  tags = {
    environment = "Production Web Server"
  }
}

resource "azurerm_virtual_machine_data_disk_attachment" "datadisk" {
  count              = var.counter
  virtual_machine_id = azurerm_linux_virtual_machine.skproject1-rg[count.index].id
  managed_disk_id    = azurerm_managed_disk.datadisk[count.index].id
  lun                = 0
  caching            = "None"
}
