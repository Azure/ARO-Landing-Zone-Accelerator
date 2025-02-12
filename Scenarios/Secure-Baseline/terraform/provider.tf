terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.16"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~>3.0.0"
    }
  }

  backend "azurerm" {
    # resource_group_name  = ""   # Partial configuration, provided during "terraform init"
    # storage_account_name = ""   # Partial configuration, provided during "terraform init"
    # container_name       = ""   # Partial configuration, provided during "terraform init"
    key = "aro-lza"
  }
}

provider "azurerm" {
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
  features {
    key_vault {
      purge_soft_delete_on_destroy = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
    }  
  }
}

provider "azuread" {

}
