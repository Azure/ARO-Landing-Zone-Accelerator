# Hub output

output "hub_vnet_id" {
  value = module.hub_network.resource_id
}

output "hub_network_name" {
  description = "The name of the hub network"
  value       = module.hub_network.name
}

output "hub_network_subnets" {
  description = "The subnets of the hub network"
  value       = module.hub_network.subnets[*]
}

output "bastion_subnet_id" {
  value = module.hub_network.subnets.bastion.resource_id
}

output "vm_subnet_id" {
  value = module.hub_network.subnets.vm.resource_id
}

# Spoke output
output "spoke_vnet_id" {
  value = module.spoke_network.resource_id
}

output "spoke_network_name" {
  description = "The name of the spoke network"
  value       = module.spoke_network.name
}

output "private_endpoint_subnet_id" {
  value = module.spoke_network.subnets.private_endpoint.resource_id
}

output "master_subnet_id" {
  value = module.spoke_network.subnets.master_aro.resource_id
}

output "worker_subnet_id" {
  value = module.spoke_network.subnets.worker_aro.resource_id
}