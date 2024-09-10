resource "azurerm_route_table" "rt" {
  name = "aro-udr"
  location = var.location
  resource_group_name = var.hub_resource_group_name
  route {
    name = "defaultRoute"
    address_prefix = "0.0.0.0/0"
    next_hop_type = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.fw.ip_configuration[0].private_ip_address
  }
}

resource "azurerm_subnet_route_table_association" "master" {
  subnet_id = module.spoke_network.subnets.master_aro.resource_id
  route_table_id = azurerm_route_table.rt.id
}

resource "azurerm_subnet_route_table_association" "worker" {
  subnet_id = module.spoke_network.subnets.worker_aro.resource_id
  route_table_id = azurerm_route_table.rt.id
}

resource "azurerm_role_assignment" "rt" {
    scope                   = azurerm_route_table.rt.id
    role_definition_name    = "Network Contributor"
    principal_id            = data.azuread_service_principal.aro_resource_provisioner.object_id
}