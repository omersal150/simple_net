# main.tf

# Provider configuration
provider "azurerm" {
  features {}
}

# Variables
variable "location" {
  description = "Azure region"
  default     = "East US"
}

variable "vnet_address_space" {
  description = "Address space for the virtual network"
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR block for the private subnet"
  default     = "10.0.2.0/24"
}

# Resource Group
resource "azurerm_resource_group" "simple_net" {
  name     = "simple-net-rg"
  location = var.location
}

# Virtual Network
resource "azurerm_virtual_network" "simple_net" {
  name                = "simple-net-vnet"
  resource_group_name = azurerm_resource_group.simple_net.name
  location            = azurerm_resource_group.simple_net.location
  address_space       = [var.vnet_address_space]
}

# Public Subnet
resource "azurerm_subnet" "public" {
  name                 = "public-subnet"
  resource_group_name  = azurerm_resource_group.simple_net.name
  virtual_network_name = azurerm_virtual_network.simple_net.name
  address_prefixes     = [var.public_subnet_cidr]
}

# Private Subnet
resource "azurerm_subnet" "private" {
  name                 = "private-subnet"
  resource_group_name  = azurerm_resource_group.simple_net.name
  virtual_network_name = azurerm_virtual_network.simple_net.name
  address_prefixes     = [var.private_subnet_cidr]
}

# Network Security Group (NSG) for web server
resource "azurerm_network_security_group" "web_nsg" {
  name                = "simple-net-web-nsg"
  location            = azurerm_resource_group.simple_net.location
  resource_group_name = azurerm_resource_group.simple_net.name

  security_rule {
    name                       = "SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "HTTP"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Network Security Group (NSG) for database server
resource "azurerm_network_security_group" "db_nsg" {
  name                = "simple-net-db-nsg"
  location            = azurerm_resource_group.simple_net.location
  resource_group_name = azurerm_resource_group.simple_net.name

  security_rule {
    name                       = "SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Postgres"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5432"
    source_address_prefix      = "10.0.1.0/24" # Restrict access to the public subnet
    destination_address_prefix = "*"
  }
}

# Public IP for web server
resource "azurerm_public_ip" "web_public_ip" {
  name                = "simple-net-web-public-ip"
  location            = azurerm_resource_group.simple_net.location
  resource_group_name = azurerm_resource_group.simple_net.name
  allocation_method   = "Dynamic"
}

# NIC for web server
resource "azurerm_network_interface" "web_nic" {
  name                = "simple-net-web-nic"
  location            = azurerm_resource_group.simple_net.location
  resource_group_name = azurerm_resource_group.simple_net.name

  ip_configuration {
    name                          = "web-ip-config"
    subnet_id                     = azurerm_subnet.public.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.web_public_ip.id
  }
}

# Virtual Machine for web server
resource "azurerm_linux_virtual_machine" "web_vm" {
  name                            = "simple-net-web-vm"
  resource_group_name             = azurerm_resource_group.simple_net.name
  location                        = azurerm_resource_group.simple_net.location
  size                            = "Standard_B1s" # or any suitable size
  admin_username                  = "adminuser"
  admin_password                  = "Password123!" # or generate dynamically
  disable_password_authentication = false

  network_interface_ids = [
    azurerm_network_interface.web_nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}

# Database server (PostgreSQL)
resource "azurerm_linux_virtual_machine" "db_vm" {
  name                            = "simple-net-db-vm"
  resource_group_name             = azurerm_resource_group.simple_net.name
  location                        = azurerm_resource_group.simple_net.location
  size                            = "Standard_B1s" # or any suitable size
  admin_username                  = "adminuser"
  admin_password                  = "Password123!" # or generate dynamically
  disable_password_authentication = false

  network_interface_ids = [
    azurerm_subnet.private.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}

# Output the public IP address of the web server
output "web_server_public_ip" {
  value = azurerm_public_ip.web_public_ip.ip_address
}
