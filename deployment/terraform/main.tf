data "azurerm_client_config" "current" {}

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

  location                   = var.location
  hub_vnet_id                = module.vnet.hub_vnet_id
  spoke_vnet_id              = module.vnet.spoke_vnet_id
  private_endpoint_subnet_id = module.vnet.private_endpoint_subnet_id

  depends_on = [
    module.vnet
  ]
}

module "aro" {
  source = "./modules/aro"

  location = var.location

  spoke_vnet_id = module.vnet.spoke_vnet_id
  master_subnet_id = module.vnet.master_subnet_id
  worker_subnet_id = module.vnet.worker_subnet_id

  aro_sp_object_id = var.aro_sp_object_id
  aro_sp_password = var.aro_sp_password
  aro_rp_object_id = var.aro_rp_object_id

  depends_on = [
    module.vnet
  ]
}

# module "frontdoor" {
#   source = "./modules/frontdoor"

#   location = var.location
#   aro_worker_subnet_id = module.vnet.worker_subnet_id
#   aro_lb_frontend_ips = "" # Needs to be pullede from ARO and is not deploying correctly
#   la_id = azurerm_log_analytics_workspace.la.id
#   random = random_string.random.result
# }