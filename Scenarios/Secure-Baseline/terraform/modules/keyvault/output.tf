output "kv_id" {
  value = azurerm_key_vault.kv.id
  depends_on = [
    azurerm_key_vault_secret.vm_admin_password,
      ]
}

output "vm_admin_password" {
  value = var.vm_admin_password  
  sensitive = true
}

output "kv_hub_name" {
  value = azurerm_key_vault.kv.name
}