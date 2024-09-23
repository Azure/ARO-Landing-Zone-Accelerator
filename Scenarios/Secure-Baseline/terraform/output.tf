# Resource Groups

output "hub_resource_group_name" {
  value = azurerm_resource_group.hub.name
}

output "spoke_resource_group_name" {
  value = azurerm_resource_group.spoke.name
}

output "log_analytics_workspace_id" {
  value = azurerm_log_analytics_workspace.la.id
}

# Networking 
output "hub_vnet_id" {
  value = module.vnet.hub_vnet_id

}

output "hub_network_name" {
  description = "The name of the hub network"
  value       = module.vnet.hub_network_name
}

output "hub_network_subnets" {
  description = "The subnets of the hub network"
  value       = module.vnet.hub_network_subnets
}

output "bastion_subnet_id" {
  value = module.vnet.bastion_subnet_id
}

output "vm_subnet_id" {
  value = module.vnet.vm_subnet_id
}

output "spoke_vnet_id" {
  value = module.vnet.spoke_vnet_id
}

output "private_endpoint_subnet_id" {
  value = module.vnet.private_endpoint_subnet_id
}

output "master_subnet_id" {
  value = module.vnet.master_subnet_id
}

output "worker_subnet_id" {
  value = module.vnet.worker_subnet_id
}

output "console_url" {
  value = module.aro.console_url
}

output "api_server_ip" {
  value = module.aro.api_server_ip
}

output "ingress_ip" {
  value = module.aro.ingress_ip

}
