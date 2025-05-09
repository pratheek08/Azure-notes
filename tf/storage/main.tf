provider "azurerm" {
  features {}
}

# Reference existing resource group
data "azurerm_resource_group" "existing" {
  name = "pratheekRG"
}

resource "azurerm_storage_account" "example" {
  name                     = "pratheekstoragetf"  # must be globally unique!
  resource_group_name      = data.azurerm_resource_group.existing.name
  location                 = data.azurerm_resource_group.existing.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  allow_blob_public_access = true  # optional based on your use case
}

resource "azurerm_storage_container" "example" {
  name                  = "pratheekcontainertf"
  storage_account_name  = azurerm_storage_account.example.name
  container_access_type = "private"  # or "blob", "container"
}
