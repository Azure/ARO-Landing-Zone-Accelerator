terraform {
  required_providers {
    azureopenshift = {
      source    = "rh-mobb/azureopenshift"
      version   = "~>0.0.5"
    }
  }
}

# Needed so we can assign it the 'Network Contributor' role on the created VNet
data "azuread_service_principal" "aro_resource_provisioner" {
    display_name            = "Azure Red Hat OpenShift RP"
}

resource "azuread_application" "cluster" {
    display_name            = "openshift-cluster-${var.base_name}"
    owners                  = [data.azuread_client_config.current.object_id]
}

resource "azuread_application_password" "cluster" {
    application_object_id   = azuread_application.cluster.object_id
}

resource "azuread_service_principal" "cluster" {
    application_id  = azuread_application.cluster.application_id
    owners          = [data.azuread_client_config.current.object_id]
}

resource "azurerm_role_assignment" "main" {
        scope                   = data.azurerm_subscription.current.id
        role_definition_name    = "Contributor"
        principal_id            = azuread_service_principal.cluster.object_id
}

resource "azurerm_role_assignment" "spoke_vnet" {
    scope                   = var.spoke_vnet_id
    role_definition_name    = "Network Contributor"
    principal_id            = data.azuread_service_principal.aro_resource_provisioner.object_id
}

resource "azurerm_role_assignment" "hub_vnet" {
    scope                   = var.hub_vnet_id
    role_definition_name    = "Network Contributor"
    principal_id            = data.azuread_service_principal.aro_resource_provisioner.object_id
}

resource "azurerm_role_assignment" "resource_provider_assignment" {
  count                = length(var.roles)
  scope                = data.azurerm_subscription.current.id
  role_definition_name = var.roles[count.index].role
  principal_id         = data.azuread_service_principal.aro_resource_provisioner.object_id
}

resource "azureopenshift_redhatopenshift_cluster" "cluster" {
  name                = "openshift-cluster-${var.base_name}"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.spoke.name
  master_profile {
    subnet_id = var.master_subnet_id
    vm_size  = "Standard_D8s_v3"
  }
  worker_profile {
    subnet_id = var.worker_subnet_id
    vm_size  = "Standard_D8s_v3"
    disk_size_gb = 128
    node_count = 3
  }
  ingress_profile {
    visibility = "Private"
  }
  api_server_profile {
    visibility = "Private"
  }
  network_profile {
    pod_cidr = "10.128.0.0/14"
    service_cidr = "172.30.0.0/16"
  }

  service_principal {
    client_id     = azuread_application.cluster.application_id
    client_secret = azuread_application_password.cluster.value
  }
  cluster_profile {
    domain = "ratingsapp.${var.base_name}.com"
  }
  depends_on = [
    azurerm_role_assignment.hub_vnet
  ]
}

