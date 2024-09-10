terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~>2.43"
    }

    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.114.0"
  
    }
    
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }

}
