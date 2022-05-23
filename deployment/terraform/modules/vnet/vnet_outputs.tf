output "bastion_subnet_id" {
  value = azurerm_subnet.bastion.id
}

output "vm_subnet_id" {
  value = azurerm_subnet.vm.id
}

output "hub_vnet_id" {
  value = azurerm_virtual_network.hub.id

}

output "spoke_vnet_id" {
  value = azurerm_virtual_network.spoke.id
}

output "private_endpoint_subnet_id" {
  value = azurerm_subnet.private_endpoint.id
}