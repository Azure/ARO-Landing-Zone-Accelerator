## ARO Cluster

locals {
    domain = var.domain != null ? var.domain : random_string.domain.result
}

resource "random_string" "domain" {
  length           = 8
  special          = false
  upper            = false
  numeric          = false
}

# See docs at https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/redhat_openshift_cluster
resource "azurerm_role_assignment" "resource_provider_assignment" {
  count                = length(var.roles)
  scope                = data.azurerm_subscription.current.id
  role_definition_name = var.roles[count.index].role
  principal_id         = var.aro_rp_object_id
}

resource "azurerm_redhat_openshift_cluster" "cluster" {
  name                = var.cluster_name
  location            = var.location
  resource_group_name = var.spoke_resource_group_name
  tags                = var.tags



  cluster_profile {
    domain      = var.domain
    pull_secret = var.pull_secret_path
    version     = var.aro_version
  }

  main_profile {
    vm_size   = var.main_vm_size
    #subnet_id = azurerm_subnet.control_plane_subnet.id
    subnet_id = var.master_subnet_id
  }

  worker_profile {
    #subnet_id    = azurerm_subnet.machine_subnet.id
    subnet_id    = var.worker_subnet_id
    disk_size_gb = var.worker_disk_size_gb
    node_count   = var.worker_node_count
    vm_size      = var.worker_vm_size
  }

  network_profile {
    outbound_type = var.outbound_type
    pod_cidr      = var.aro_pod_cidr_block
    service_cidr  = var.aro_service_cidr_block
  }

  api_server_profile {
    visibility = var.api_server_profile
  }

  ingress_profile {
    visibility = var.ingress_profile
  }

  service_principal {
    client_id     = var.sp_client_id
    client_secret = var.sp_client_secret
  }

  depends_on = [
    azurerm_role_assignment.resource_provider_assignment
  ]
}

