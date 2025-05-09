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

variable "server_config" {
  description = "Configuration for the Azure Virtual Machines"
  type = map(object({
    os_type   = string
    publisher = string
    offer     = string
    sku       = string
    vm_size   = string
  }))
  default = {
    "web-server-a" = {
      os_type   = "Linux"
      publisher = "Canonical"
      offer     = "UbuntuServer"
      sku       = "18.04-LTS"
      vm_size   = "Standard_DS1_v2"
    },
    "app-server-b" = {
      os_type   = "Windows"
      publisher = "MicrosoftWindowsServer"
      offer     = "WindowsServer"
      sku       = "2019-Datacenter"
      vm_size   = "Standard_DS2_v2"
    }
  }
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "pratheek-RG"
}

variable "location" {
  description = "Location for the resources"
  type        = string
  default     = "centralindia"
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "vnet" {
  name                = "myVNet"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "mySubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.0.0/24"]
}

resource "azurerm_public_ip" "public_ip" {
  for_each            = var.server_config
  name                = "${each.key}-public-ip"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "nic" {
  for_each            = var.server_config
  name                = "${each.key}-nic"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip[each.key].id
  }
}

resource "azurerm_virtual_machine" "vm" {
  for_each              = var.server_config
  name                  = each.key
  location              = var.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.nic[each.key].id]
  vm_size               = each.value.vm_size

  delete_os_disk_on_termination = true
  delete_data_disks_on_termination = true

  storage_os_disk {
    name              = "${each.key}-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_image_reference {
    publisher = each.value.publisher
    offer     = each.value.offer
    sku       = each.value.sku
    version   = "latest"
  }

  os_profile {
    computer_name  = each.key
    admin_username = "myadmin"
    admin_password = "Password1234!"
  }

  dynamic "os_profile_linux_config" {
    for_each = each.value.os_type == "Linux" ? [1] : []
    content {
      disable_password_authentication = false
    }
  }

  dynamic "os_profile_windows_config" {
    for_each = each.value.os_type == "Windows" ? [1] : []
    content {
      provision_vm_agent        = true
      enable_automatic_upgrades = true
    }
  }

  tags = {
    environment = "dev"
  }
}
