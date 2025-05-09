provider "azurerm" {
  features {}
}
 
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "2.40.0"
    }
  }
}
resource "azurerm_resource_group" "example" {
  name     = "pratheekR${count.index+1}"
  location = "eastus"
  count=2
}
