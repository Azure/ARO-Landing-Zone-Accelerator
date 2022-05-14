# Resource Groups
resource "azurerm_resource_group" "hub" {
  name     = var.hub_name
  location = var.location
}

resource "azurerm_resource_group" "spoke" {
  name     = var.spoke_name
  location = var.location
}

module "vnet" {
  source = "./modules/vnet"

  hub_name    = var.hub_name
  hub_rg_name = azurerm_resource_group.hub.name

  spoke_name    = var.spoke_name
  spoke_rg_name = azurerm_resource_group.spoke.name

  location = var.location

}