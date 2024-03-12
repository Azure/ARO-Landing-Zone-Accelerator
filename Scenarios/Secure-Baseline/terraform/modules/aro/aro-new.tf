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

resource "azurerm_redhat_openshift_cluster" "aro_cluster" {
    name                = "openshift-cluster-${var.base_name}"
    resource_group_name = "openshift-cluster-${var.base_name}"
    location            = var.location

    cluster_profile {
    domain  = "domain-openshift-cluster-${var.base_name}"
    version = "4.13.23"
    }

    network_profile {
    pod_cidr     = "10.128.0.0/14"
    service_cidr = "172.30.0.0/16"
  }

  main_profile {
    vm_size   = "Standard_D8s_v3"
    subnet_id = var.master_subnet_id
  }

  api_server_profile {
    visibility = "Private"
  }

  ingress_profile {
    visibility = "Private"
  }

  worker_profile {
    vm_size      = "Standard_D4s_v3"
    disk_size_gb = 128
    node_count   = 3
    subnet_id    = var.worker_subnet_id
  }

  service_principal {
    client_id     = var.sp_client_id
    client_secret = var.sp_client_secret
  }

 depends_on = [
    azurerm_role_assignment.resource_provider_assignment
  ]
       
}
