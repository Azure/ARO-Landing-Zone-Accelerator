module "hub_network" {
  source              = "Azure/avm-res-network-virtualnetwork/azurerm"
  version             = "~> 0.2"
  location            = var.location
  resource_group_name = var.hub_resource_group_name
  address_space       = var.hub_prefix
  name                = var.hub_name
  // Optional: Define subnets
  subnets = {
    "fw" = {
      name             = "AzureFirewallSubnet"
      address_prefixes = var.fw_subnet_prefix
    }
    "bastion" = {
      name             = "AzureBastionSubnet"
      address_prefixes = var.bastion_subnet_prefix
    }
    "vm" = {
     name              = var.vm_subnet_name
      address_prefixes = var.vm_subnet_prefix 
    }
  }
}