output "sp_client_id" {
    value = azuread_application.aro-lza-sp.id
}

output "sp_client_secret" {
    value = azuread_application_password.sp_client_secret.value
    sensitive=true
}
