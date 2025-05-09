provider "azurerm" {

 features {}

}

# Define the resource group

resource "azurerm_resource_group" "example" {

 name = "pratheekRG1"

 location = "centralindia"

}

# Define the virtual network

resource "azurerm_virtual_network" "example" {

 name = "pratheek_vnet"

 location = azurerm_resource_group.example.location

 resource_group_name = azurerm_resource_group.example.name

 address_space = ["10.0.0.0/16"]

}

# Define the subnet

resource "azurerm_subnet" "example" {

 name = "pratheek_subnet"

 resource_group_name = azurerm_resource_group.example.name

 virtual_network_name = azurerm_virtual_network.example.name

 address_prefixes = ["10.0.1.0/24"]

}

# Define the Network Interface Card (NIC)

resource "azurerm_network_interface" "example" {

 name = "pratheek-nic"

 location = azurerm_resource_group.example.location

 resource_group_name = azurerm_resource_group.example.name

 # IP configuration block

 ip_configuration {

  name = "internal"

  subnet_id = azurerm_subnet.example.id

  private_ip_address_allocation = "Dynamic"

 }

 tags = {

  environment = "backend"

 }

}

# Define the VM

resource "azurerm_linux_virtual_machine" "example" {

 name = "pratheekVM"

 resource_group_name = azurerm_resource_group.example.name

 location = azurerm_resource_group.example.location

 size = "Standard_B1s"

 admin_username = "azureuser"

 # OS disk block

 os_disk {

  name = "akash-backend-os-disk"

  caching = "ReadWrite"

  storage_account_type = "Standard_LRS"

  disk_size_gb = 30

 }

 admin_ssh_key {

  username = "azureuser"

  public_key = file("~/.ssh/id_rsa.pub") # You can generate a new SSH key if you want

 }

 # Specify the image using source_image_reference

 source_image_reference {

  publisher = "Canonical"

  offer = "0001-com-ubuntu-server-jammy"

  sku = "22_04-lts"

  version = "latest"

 }

 network_interface_ids = [azurerm_network_interface.example.id]

 tags = {

  environment = "backend"

 }

}

terraform{

 required_providers {

  azurerm = {

   source = "hashicorp/azurerm"

   version = "2.40.0"

  }

 }

}

