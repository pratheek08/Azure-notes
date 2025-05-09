provider "azurerm" {
  features {}
  subscription_id = "bf7e75db-e819-49ca-b6d2-69c32a2353fe"
}

# Existing Resource Group
resource "azurerm_resource_group" "rg" {
  name = "pratheekRG1"
  location = "eastus"
}

# Virtual Network and Subnets
resource "azurerm_virtual_network" "vnet" {
  name                = "pratheek-vnet"
  address_space       = ["10.55.0.0/16"]
  location            = resource.azurerm_resource_group.rg.location
  resource_group_name = resource.azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "public_subnet" {
  name                 = "public"
  resource_group_name  = resource.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.55.1.0/24"]
}

resource "azurerm_subnet" "private_subnet" {
  name                 = "private"
  resource_group_name  = resource.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.55.2.0/24"]
}

# Load Balancer and Public IP
resource "azurerm_public_ip" "lb_public_ip" {
  name                = "pratheek-public-ip"
  location            = resource.azurerm_resource_group.rg.location
  resource_group_name = resource.azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_lb" "lb" {
  name                = "pratheek-lb"
  location            = resource.azurerm_resource_group.rg.location
  resource_group_name = resource.azurerm_resource_group.rg.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "PublicFrontend"
    public_ip_address_id = azurerm_public_ip.lb_public_ip.id
  }
}

resource "azurerm_lb_backend_address_pool" "backend_pool" {
  name            = "pratheek-backend-pool"
  loadbalancer_id = azurerm_lb.lb.id
}

resource "azurerm_lb_probe" "http_probe" {
  name            = "http-probe"
  loadbalancer_id = azurerm_lb.lb.id
  protocol        = "Tcp"
  port            = 80
}

# Corrected `azurerm_lb_rule` (no `resource_group_name`, and using `backend_address_pool_ids`)
resource "azurerm_lb_rule" "http_rule" {
  name                           = "http-rule"
  loadbalancer_id                = azurerm_lb.lb.id
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "PublicFrontend"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.backend_pool.id]
  probe_id                       = azurerm_lb_probe.http_probe.id
}

# NSG for VMSS Subnet
resource "azurerm_network_security_group" "web_nsg" {
  name                = "pratheek-nsg"
  location            = resource.azurerm_resource_group.rg.location
  resource_group_name = resource.azurerm_resource_group.rg.name

  security_rule {
    name                       = "AllowHTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "nsg_assoc" {
  subnet_id                 = azurerm_subnet.private_subnet.id
  network_security_group_id = azurerm_network_security_group.web_nsg.id
}

# VM Scale Set
resource "azurerm_linux_virtual_machine_scale_set" "vmss" {
  name                             = "pratheek-vmss"
  resource_group_name              = resource.azurerm_resource_group.rg.name
  location                         = resource.azurerm_resource_group.rg.location
  sku                              = "Standard_B1s"
  instances                        = 3
  admin_username                   = "pratheek"
  admin_password                   = "qwerty@1234"  # Replace in real deployments
  disable_password_authentication = false
  source_image_id                  = "/subscriptions/bf7e75db-e819-49ca-b6d2-69c32a2353fe/resourceGroups/pratheekRG/providers/Microsoft.Compute/galleries/pratheekAZgallery/images/pratheek-img/versions/0.0.1"
  upgrade_mode                     = "Manual"
  # security_type = "TrustedLaunch"
  secure_boot_enabled = true

  network_interface {
    name    = "vmss-nic"
    primary = true

    ip_configuration {
      name                                   = "internal"
      primary                                = true
      subnet_id                              = azurerm_subnet.private_subnet.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.backend_pool.id]
    }
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
}

# Output Public IP of Load Balancer
output "load_balancer_ip" {
  value = azurerm_public_ip.lb_public_ip.ip_address
}
