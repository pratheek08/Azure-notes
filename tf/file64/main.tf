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
resource "azurerm_resource_group" "main" {
  name     = "pratheekRG2"
  location = "centralindia"
}

# Public IP
resource "azurerm_public_ip" "public_ip" {
  name                = "pratheek-public-ip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Dynamic"
  sku                 = "Basic"
}

# Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "pratheek-vnet-3"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = ["10.0.0.0/16"]
}

# Subnet
resource "azurerm_subnet" "subnet" {
  name                 = "backend-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# NIC
resource "azurerm_network_interface" "nic_vm" {
  name                = "pratheek-nic-2"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}

# VM
resource "azurerm_linux_virtual_machine" "vm" {
  name                = "pratheekVM"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  size                = "Standard_B1s"
  admin_username      = "user14"

  network_interface_ids = [azurerm_network_interface.nic_vm.id]

  admin_ssh_key {
    username   = "user14"
    public_key = file("/home/user14/.ssh/id_rsa.pub")
  }

  os_disk {
    name                 = "pratheek-os-disk"
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

  custom_data = filebase64("java.sh")
  tags = {
    environment = "frontend"
    name        = "pratheek"
  }
}
