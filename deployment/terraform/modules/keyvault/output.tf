output "kv_id" {
  value = azurerm_key_vault.kv.id
  depends_on = [
    azurerm_key_vault_secret.vm_admin_password,
    azurerm_key_vault_secret.vm_admin_username,
  ]
}