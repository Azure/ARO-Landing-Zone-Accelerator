data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "spoke" {
  name = var.spoke_rg_name
}
