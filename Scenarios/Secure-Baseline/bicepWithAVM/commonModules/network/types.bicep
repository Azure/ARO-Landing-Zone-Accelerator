@export()
@description('A subnet configuration type. Contains a list of subnets which contain the name, address prefix, private link service network policies, and network security group name.')
type subnetType = {
  @description('The name of the subnet.')
  name: string
  addressPrefix: string
  privateLinkServiceNetworkPolicies: 'Enabled' | 'Disabled'?
  networkSecurityGroupResourceId: string?
}
