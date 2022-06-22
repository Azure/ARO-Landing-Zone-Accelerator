resource "azuread_application" "aro" {
  display_name = "aro"
  owners = [data.azuread_client_config.current.object_id]
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
      value = var.aro_sp_object_id    }
    "clientSecret" = {
      value = var.aro_sp_password
    }
    "clusterName" = {
      value = "openshift-cluster-${var.base_name}"
    }
    "clusterResourceGroupName" = {
      value = "openshift-cluster-${var.base_name}"
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
    azurerm_role_assignment.resource_provider_assignment
  ]
}