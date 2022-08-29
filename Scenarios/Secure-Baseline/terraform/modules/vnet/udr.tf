resource "azurerm_route_table" "rt" {
  name = "aro-udr"
  location = var.location
  resource_group_name = var.hub_rg_name

  route {
    name = "defaultRoute"
    address_prefix = "0.0.0.0/0"
    next_hop_type = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.fw.ip_configuration[0].private_ip_address
  }
}

resource "azurerm_subnet_route_table_association" "master" {
  subnet_id = azurerm_subnet.master_aro.id
  route_table_id = azurerm_route_table.rt.id
}

resource "azurerm_subnet_route_table_association" "worker" {
  subnet_id = azurerm_subnet.worker_aro.id
  route_table_id = azurerm_route_table.rt.id
}