# Resource Groups
resource "azurerm_resource_group" "hub" {
  name     = var.hub_name
  location = var.location
}

resource "azurerm_resource_group" "spoke" {
  name     = var.spoke_name
  location = var.location
}

resource "azurerm_log_analytics_workspace" "la" {
  name                = var.hub_name
  location            = var.location
  resource_group_name = azurerm_resource_group.hub.name
  sku                 = "PerGB2018"
}

module "vnet" {
  source = "./modules/vnet"

  hub_name    = var.hub_name
  hub_rg_name = azurerm_resource_group.hub.name

  spoke_name    = var.spoke_name
  spoke_rg_name = azurerm_resource_group.spoke.name

  location = var.location
  la_id    = azurerm_log_analytics_workspace.la.id
}

resource "random_password" "pw" {
  length      = 16
  special     = true
  min_lower   = 3
  min_special = 2
  min_upper   = 3

  keepers = {
    location = var.location
  }
}

resource "random_string" "user" {
  length  = 16
  special = false

  keepers = {
    location = var.location
  }
}


module "kv" {
  source = "./modules/keyvault"

  kv_name             = var.hub_name
  location            = var.location
  resource_group_name = azurerm_resource_group.hub.name
  vm_admin_username   = random_string.user.result
  vm_admin_password   = random_password.pw.result
}

module "vm" {
  source = "./modules/vm"

  resource_group_name = azurerm_resource_group.hub.name
  location            = var.location
  bastion_subnet_id   = module.vnet.bastion_subnet_id
  kv_id               = module.kv.kv_id
  vm_subnet_id        = module.vnet.vm_subnet_id
}

module "supporting" {
  source = "./modules/supporting"

  depends_on = [
    module.vnet
  ]
}