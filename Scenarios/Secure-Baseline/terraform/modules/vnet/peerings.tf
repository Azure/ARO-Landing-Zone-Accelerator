resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  name = "${var.hub_name}To${var.spoke_name}"
  resource_group_name = var.hub_rg_name
  virtual_network_name = azurerm_virtual_network.hub.name
  remote_virtual_network_id = azurerm_virtual_network.spoke.id
  allow_forwarded_traffic = true
  depends_on = [ azurerm_virtual_network.hub, azurerm_virtual_network.spoke ]
}

resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  name = "${var.spoke_name}To${var.hub_name}"
  resource_group_name = var.spoke_rg_name
  virtual_network_name = azurerm_virtual_network.spoke.name
  remote_virtual_network_id = azurerm_virtual_network.hub.id
  allow_forwarded_traffic = true
  depends_on = [ azurerm_virtual_network.hub, azurerm_virtual_network.spoke, azurerm_virtual_network_peering.hub_to_spoke ]
}