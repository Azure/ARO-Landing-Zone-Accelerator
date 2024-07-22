@export()
@description('A subnet configuration type. Contains a list of subnets which contain the name, address prefix, private link service network policies, and network security group name.')
type subnetType = {
  @description('The name of the subnet. Must be unique within the virtual network. Use only alphanumeric characters, periods, underscores and hyphens. Length must be between 1 and 80 characters.')
  name: string
  
  @description('The address prefix for the subnet.')
  addressPrefix: string
  
  @description('Enable or Disable apply network policies on private link service in the subnet.')
  privateLinkServiceNetworkPolicies: 'Enabled' | 'Disabled'?
  
  @description('The resource id of the network security group associated with the subnet (Optional).')
  networkSecurityGroupResourceId: string?

  @description('The resource id of the route table associated with the subnet (Optional).')
  routeTableResourceId: string?
}
