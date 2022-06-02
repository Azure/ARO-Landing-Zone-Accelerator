resource "azuread_application" "aro" {
  display_name = "aro"
  owners = [data.azuread_client_config.current.object_id]
}

resource "azuread_service_principal" "aro" {
  application_id = azuread_application.aro.application_id
  app_role_assignment_required = false
  owners = [data.azuread_client_config.current.object_id]
}

resource "azuread_application_password" "aro" {
  application_object_id = azuread_application.aro.object_id
}

resource "azurerm_resource_group" "aro_cluster" {
  name = "openshift-cluster-${var.base_name}"
  location = var.location
}

resource "azurerm_role_assignment" "virtual_network_assignment" {
  count                = length(var.roles)
  scope                = var.spoke_vnet_id
  role_definition_name = var.roles[count.index].role
  principal_id         = azuread_service_principal.aro.object_id
}

resource "azurerm_role_assignment" "resource_provider_assignment" {
  count                = length(var.roles)
  scope                = data.azurerm_subscription.current.id
  role_definition_name = var.roles[count.index].role
  principal_id         = var.aro_rp_object_id
}

resource "azurerm_resource_group_template_deployment" "aro" {
  name = var.base_name
  resource_group_name = data.azurerm_resource_group.spoke.name
  deployment_mode = "Incremental"
  parameters_content = jsonencode({
    "clientId" = {
      value = azuread_application.aro.object_id
    }
    "clientSecret" = {
      value = azuread_application_password.aro.value
    }
    "clusterName" = {
      value = "openshift-cluster-${var.base_name}"
    }
    "clusterResourceGroupName" = {
      value = azurerm_resource_group.aro_cluster.name
    }
    "domain" = {
      value = "ratingsapp.${var.base_name}.com"
    }
    "location" = {
      value = var.location
    }
    "masterSubnetId" = {
      value = var.master_subnet_id
    }
    "workerSubnetId" = {
      value = var.worker_subnet_id
    }
  })
  template_content = file("${path.module}/aro-arm.json")

  depends_on = [
    azurerm_resource_group.aro_cluster,
    azurerm_role_assignment.virtual_network_assignment,
    azurerm_role_assignment.resource_provider_assignment
  ]
}