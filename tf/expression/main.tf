provider "azurerm" {
  features {}
}

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0"
    }
  }
}

variable "test" {
  description = "Set to true for dev, false for prod"
  type        = bool
  default     = false
}

locals {
  bucket_name = var.test ? "dev" : "prod"
}

output "bucket_name" {
  value = local.bucket_name
}
