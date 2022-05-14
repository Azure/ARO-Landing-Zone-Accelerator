resource "azurerm_virtual_network" "spoke" {
  name = var.spoke_name
  location = var.location
  resource_group_name = var.spoke_rg_name

  address_space = var.spoke_prefix

  subnet {
    name = var.app_gw_subnet
    address_prefix = var.app_gw_subnet_prefix
  }

  subnet {
    name = var.private_runner_name
    address_prefix = var.private_runner_subnet_prefix
  }
}


resource "azurerm_subnet" "master_aro" {
  name = var.master_aro_name
  resource_group_name = var.spoke_rg_name
  virtual_network_name = azurerm_virtual_network.spoke.name
  address_prefixes = var.master_aro_subnet_prefix
  enforce_private_link_service_network_policies = true
}

resource "azurerm_subnet" "worker_aro" {
  name = var.worker_aro_name
  resource_group_name = var.spoke_rg_name
  virtual_network_name = azurerm_virtual_network.spoke.name
  address_prefixes = var.worker_aro_subnet_prefix
  enforce_private_link_service_network_policies = true
}

resource "azurerm_subnet" "private_endpoint" {
  name = var.private_endpoint_subnet_name
  resource_group_name = var.spoke_rg_name
  virtual_network_name = azurerm_virtual_network.spoke.name
  address_prefixes = var.private_endpoint_subnet_prefix
  enforce_private_link_service_network_policies = true
}