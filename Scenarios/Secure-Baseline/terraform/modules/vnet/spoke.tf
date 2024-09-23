module "spoke_network" {
  source              = "Azure/avm-res-network-virtualnetwork/azurerm"
  version             = "~> 0.2"
  location            = var.location
  resource_group_name = var.spoke_resource_group_name
  address_space       = var.spoke_prefix
  name                = var.spoke_name
  subnets = {
    "gw" = {
      name             = var.app_gw_subnet
      address_prefixes = var.app_gw_subnet_prefix
    }
    "master_aro" = {
      name             = var.master_aro_name
      address_prefixes = var.master_aro_subnet_prefix
      private_endpoint_network_policies_enabled = true
      private_link_service_network_policies_enabled = false
      service_endpoints = [ "Microsoft.ContainerRegistry", "Microsoft.Storage" ]

    }
    "worker_aro" = {
      name             = var.worker_aro_name
      address_prefixes = var.worker_aro_subnet_prefix
      private_link_service_network_policies_enabled = false
      private_endpoint_network_policies_enabled = true
      service_endpoints = [ "Microsoft.ContainerRegistry", "Microsoft.Storage" ]
    }

    "private_endpoint" = {
      name             = var.private_endpoint_subnet_name
      address_prefixes = var.private_endpoint_subnet_prefix
      private_link_service_network_policies_enabled = true
    }

  }


}