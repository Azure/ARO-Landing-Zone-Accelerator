resource "azurerm_virtual_network" "hub" {
  name = var.hub_name
  location = var.location
  resource_group_name = var.resource_group_name

  address_space = var.hub_prefix

  subnet {
    name = "AzureBastionSubnet"
    address_prefix = var.bastion_subnet_prefix
  }

  subnet {
    name = var_vm_subnet_name
    address_prefix = var.vm_subnet_prefix
  }

  tags = var.tags
}

resource "azurerm_subnet" "fw" {
  name = AzureFirewallSubnet
  resource_group_name = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes = var.fw_subnet_prefix
}