resource "azurerm_virtual_network" "hub" {
  name = var.hub_name
  location = var.location
  resource_group_name = var.hub_rg_name
  address_space = var.hub_prefix
}

resource "azurerm_subnet" "fw" {
  name = "AzureFirewallSubnet"
  resource_group_name = var.hub_rg_name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes = var.fw_subnet_prefix
}

resource "azurerm_subnet" "bastion" {
  name = "AzureBastionSubnet"
  resource_group_name = var.hub_rg_name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes = var.bastion_subnet_prefix
}

resource "azurerm_subnet" "vm" {
  name = var.vm_subnet_name
  resource_group_name = var.hub_rg_name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes = var.vm_subnet_prefix
}