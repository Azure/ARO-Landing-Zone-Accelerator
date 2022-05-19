output "bastion_subnet_id" {
  value = azurerm_subnet.bastion.id
}

output "vm_subnet_id" {
  value = azurerm_subnet.vm.id
}