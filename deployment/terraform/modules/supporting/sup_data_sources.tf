data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "spoke" {
  name = var.spoke_rg_name
}

data "azurerm_resource_group" "hub" {
  name = var.hub_rg_name
}

data "azurerm_virtual_network" "spoke_vnet" {
  name = var.spoke_vnet_name
  resource_group_name = data.azurerm_resource_group.spoke.name
}

data "azurerm_virtual_network" "hub_vnet" {
  name = var.hub_vnet_name
  resource_group_name = data.azurerm_resource_group.hub.name
}

data "azurerm_subnet" "private_endpoint_subnet_name" {
  name = var.private_endpoint_subnet_name
  virtual_network_name = data.azurerm_virtual_network.spoke_vnet.name
  resource_group_name = var.spoke_rg_name
}