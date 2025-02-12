resource "azuread_application" "aro-lza-sp" {
  display_name = var.aro_spn_name
  owners       = [data.azuread_client_config.current.object_id]
}

resource "azuread_service_principal" "aro-lza-sp" {
  client_id = azuread_application.aro-lza-sp.client_id
  app_role_assignment_required = false
  owners                       = [data.azuread_client_config.current.object_id]
}

resource "time_rotating" "password-rotation" {
  rotation_days = 365
}

resource "azuread_application_password" "sp_client_secret" {
  application_id = azuread_application.aro-lza-sp.object_id
  display_name = "rbac"
  rotate_when_changed = {
    rotation = time_rotating.password-rotation.id
  }
}

resource "azurerm_role_assignment" "aro" {
  scope                = data.azurerm_resource_group.spoke.id
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.aro-lza-sp.object_id
}

resource "azurerm_role_assignment" "aro-hub" {
  scope                = data.azurerm_resource_group.hub.id
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.aro-lza-sp.object_id
}