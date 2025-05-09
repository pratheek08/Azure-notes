provider "azurerm" {
  features {}
}

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.27.0"
    }
  }
}

# Resource Group
resource "azurerm_resource_group" "example" {
  name     = "pratheekRG1"
  location = "centralindia"
}

# Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "pratheek-vnet-1"
  location            = "eastus"
  resource_group_name = azurerm_resource_group.example.name
  address_space       = ["10.0.0.0/16"]
}

# Subnet
resource "azurerm_subnet" "subnet" {
  name                 = "backend-subnet"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Network Interface
resource "azurerm_network_interface" "nic_vm" {
  name                = "pratheek-nic-1"
  location            = azurerm_virtual_network.vnet.location
  resource_group_name = azurerm_resource_group.example.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Random ID (for VM name)
resource "random_id" "id" {
  byte_length = 8
}

# Linux VM
resource "azurerm_linux_virtual_machine" "vm" {
  name                = "vm-${random_id.id.hex}"  
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_virtual_network.vnet.location
  size                = "Standard_B1s"
  admin_username      = "user14"

  network_interface_ids = [azurerm_network_interface.nic_vm.id]

  admin_ssh_key {
    username   = "user14"
    public_key = file("/home/user14/.ssh/id_rsa.pub")
  }

  os_disk {
    name                 = "pratheek-backend-os-disk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 35
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }

  tags = {
    environment = "frontend"
    name        = "pratheek"
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      tags,
    ]
    # prevent_destroy = true
  }
}
