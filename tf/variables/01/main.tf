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
  name     = "myRG${var.name}"
  location = "eastus"
}
