output "sp_client_id" {
    value = azuread_application.aro-lza-sp.client_id
}

output "sp_client_secret" {
    value = azuread_service_principal_password.aro-lza-sp.value
    sensitive=true
}