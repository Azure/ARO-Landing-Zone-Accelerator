targetScope = 'subscription'

/* -------------------------------------------------------------------------- */
/*                                   IMPORTS                                  */
/* -------------------------------------------------------------------------- */

import {
  generateResourceName
  generateResourceNameFromParentResourceName
} from '../common-modules/naming/functions.bicep'

import { 
  subnetType 
} from '../common-modules/network/types.bicep'

/* -------------------------------------------------------------------------- */
/*                                 PARAMETERS                                 */
/* -------------------------------------------------------------------------- */

@description('The name of the workload. Defaults to aro-lza.')
@minLength(3)
@maxLength(15)
param workloadName string = 'aro-lza'

@description('The location of the resources. Defaults to the deployment location.')
param location string = deployment().location

@description('The type of environment. Defaults to DEV.')
@allowed([
  'DEV'
  'TST'
  'UAT'
  'PRD'
])
@minLength(3)
@maxLength(3)
param env string = 'DEV'

@minLength(3)
@maxLength(5)
@description('The hash to be added to every name like resource, subnet, etc. If not set, a unique string is generated for resources with global name based on its resource group id. The size of the hash is 5 characters.')
param hash string?

@description('The tags to apply to the resources. Defaults to an object with the environment and workload name.')
param tags object = hash == null ? {
  environment: env
  workload: workloadName
} : {
  environment: env
  workload: workloadName
  hash: hash
}

@description('Enable Azure Verified Modules (AVM) telemetry. Defaults to true.')
param enableAvmTelemetry bool = true

@description('The name of the resource group for the spoke. Defaults to the naming convention `<abbreviation-resource-group>-<workload>-<lower-case-env>-<location-short>[-<hash>]`.')
param resourceGroupName string = generateResourceName('resourceGroup', workloadName, env, location, null, hash)

/* ----------------------------- Virtual Network ---------------------------- */

@description('The resource id of the hub virtual network. This is required to peer the spoke virtual network with the hub virtual network.')
param hubVirtualNetworkResourceId string

@description('The name of the spoke virtual network. Defaults to the naming convention `<abbreviation-virtual-network>-<workload>-<lower-case-env>-<location-short>[-<hash>]`.')
@minLength(1)
@maxLength(64)
param virtualNetworkName string = generateResourceName('virtualNetwork', workloadName, env, location, null, hash)

@description('The address prefixes for the spoke virtual network. Defaults to ["10.1.0.0/16"].')
param virtualNetworkAddressPrefixes array = ['10.1.0.0/16']

@description('The DNS server array (Optional).')
param dnsServers array?

/* --------------------------- Master Nodes Subnet -------------------------- */

@description('The name of the master nodes subnet. Defaults to the naming convention `<abbreviation-subnet>-aro-master-<workloadName>-<lower-case-env>-<location-short>[-<hash>]`.')
@minLength(1)
@maxLength(80)
param masterNodesSubnetName string = generateResourceName('subnet', 'aro-master-${workloadName}', env, location, null, hash)

@description('The CIDR for the master nodes subnet. Defaults to 10.1.0.0/23.')
param masterNodesSubnetAddressPrefix string = '10.1.0.0/23'

/* --------------------------- Worker Nodes Subnet -------------------------- */

@description('The name of the worker nodes subnet. Defaults to the naming convention `<abbreviation-subnet>-aro-worker-<workloadName>-<lower-case-env>-<location-short>[-<hash>]`.')
@minLength(1)
@maxLength(80)
param workerNodesSubnetName string = generateResourceName('subnet', 'aro-worker-${workloadName}', env, location, null, hash)

@description('The CIDR for the worker nodes subnet. Defaults to 10.1.2.0/23.')
param workerNodesSubnetAddressPrefix string = '10.1.2.0/23'

/* ------------------------ Private Endpoints Subnet ------------------------ */

@description('The name of the private endpoints subnet. Defaults to the naming convention `<abbreviation-subnet>-pep-<workloadName>-<lower-case-env>-<location-short>[-<hash>]`.')
@minLength(1)
@maxLength(80)
param privateEndpointsSubnetName string = generateResourceName('subnet', 'pep-${workloadName}', env, location, null, hash)

@description('The CIDR for the private endpoints subnet. Defaults to 10.1.4.0/24.')
param privateEndpointsSubnetAddressPrefix string = '10.1.4.0/24'

@description('The name of the network security group for the private endpoints subnet. Defaults to the naming convention `<abbreviation-nsg>-<privateEndpointsSubnetName>`.')
param privateEndpointsNetworkSecurityGroupName string = generateResourceNameFromParentResourceName('networkSecurityGroup', privateEndpointsSubnetName, null, hash)

/* ----------------------------- Jumpbox Subnet ----------------------------- */

@description('The name of the jumpbox subnet. Defaults to the naming convention `<abbreviation-subnet>-jumpbox-<workloadName>-<lower-case-env>-<location-short>[-<hash>]`.')
@minLength(1)
@maxLength(80)
param jumpboxSubnetName string = generateResourceName('subnet', 'jumpbox-${workloadName}', env, location, null, hash)

@description('The CIDR for the jumpbox subnet. Defaults to 10.1.5.0/24')
param jumpboxSubnetAddressPrefix string = '10.1.5.0/24'

@description('The name of the network security group for the jumpbox subnet. Defaults to the naming convention `<abbreviation-nsg>-<jumpboxSubnetName>`.')
param jumpboxNetworkSecurityGroupName string = generateResourceNameFromParentResourceName('networkSecurityGroup', jumpboxSubnetName, null, hash)

/* ---------------------------- Front Door Subnet --------------------------- */

@description('The name of the front door subnet. Defaults to the naming convention `<abbreviation-subnet>-frontdoor-<workloadName>-<lower-case-env>-<location-short>[-<hash>]`.')
@minLength(1)
@maxLength(80)
param frontDoorSubnetName string = generateResourceName('subnet', 'frontdoor-${workloadName}', env, location, null, hash)

@description('The CIDR for the front door subnet. Defaults to 10.1.6.0/24')
param frontDoorSubnetAddressPrefix string = '10.1.6.0/24'

@description('The name of the network security group for the front door subnet. Defaults to the naming convention `<abbreviation-nsg>-<frontDoorSubnetName>`.')
param frontDoorNetworkSecurityGroupName string = generateResourceNameFromParentResourceName('networkSecurityGroup', frontDoorSubnetName, null, hash)

/* ------------------------------ Other Subnets ----------------------------- */

@description('The configuration for other subnets (Optional).')
param otherSubnets subnetType[]?

/* ------------------------------- Route Table ------------------------------ */

@description('The name of the route table for the two ARO subnets. Defaults to the naming convention `<abbreviation-route-table>-aro-<lower-case-env>-<location-short>[-<hash>]`.')
param aroRouteTableName string = generateResourceName('routeTable', 'aro', env, location, null, hash)

@description('The private IP address of the firewall to route ARO egress traffic to it (Optional). If not provided, the route table will not be created and not associated with the worker nodes and master nodes subnets.')
param firewallPrivateIpAddress string?

/* ------------------------------- Monitoring ------------------------------- */

@description('The Log Analytics workspace resource id. This is required to enable monitoring.')
param logAnalyticsWorkspaceResourceId string

/* -------------------------------------------------------------------------- */
/*                                  VARIABLES                                 */
/* -------------------------------------------------------------------------- */

var deployAroRouteTable = firewallPrivateIpAddress != null

/* --------------------------------- Peering -------------------------------- */

var hubVirtualNetworkName = last(split(hubVirtualNetworkResourceId, '/'))

var remotePeeringName = '${hubVirtualNetworkName}-to-${virtualNetworkName}-peering'

var peerings = [
  {
    name: '${virtualNetworkName}-to-${hubVirtualNetworkName}-peering'
    remotePeeringEnabled: true
    remotePeeringName: remotePeeringName
    remoteVirtualNetworkId: hubVirtualNetworkResourceId
  }
]

/* ------------------------- Netowrk Security Groups ------------------------ */

var privateEndpointsNsgSecurityRules = loadJsonContent('nsg/private-endpoints-nsg.jsonc', 'securityRules')

/* --------------------------------- Subnets -------------------------------- */

var predefinedSubnets = [
  {
    name: masterNodesSubnetName
    addressPrefix: masterNodesSubnetAddressPrefix
    privateLinkServiceNetworkPolicies: 'Disabled'
    routeTableResourceId: deployAroRouteTable ? aroRouteTable.outputs.resourceId : ''
  }
  {
    name: workerNodesSubnetName
    addressPrefix: workerNodesSubnetAddressPrefix
    privateLinkServiceNetworkPolicies: 'Disabled'
    routeTableResourceId: deployAroRouteTable ? aroRouteTable.outputs.resourceId : ''
  }
  {
    name: privateEndpointsSubnetName
    addressPrefix: privateEndpointsSubnetAddressPrefix
    networkSecurityGroupResourceId: privateEndpointsNetworkSecurityGroup.outputs.resourceId
  }
  {
    name: jumpboxSubnetName
    addressPrefix: jumpboxSubnetAddressPrefix
    networkSecurityGroupResourceId: jumpboxNetworkSecurityGroup.outputs.resourceId
  }
  {
    name: frontDoorSubnetName
    addressPrefix: frontDoorSubnetAddressPrefix
    privateLinkServiceNetworkPolicies: 'Disabled'
    networkSecurityGroupResourceId: frontDoorNetworkSecurityGroup.outputs.resourceId
  }
]

var subnets = concat(predefinedSubnets, otherSubnets ?? [])

/* ------------------------------- Monitoring ------------------------------- */

var diagnosticsSettings = [
  {
    logAnalyticsDestinationType: 'AzureDiagnostics'
    workspaceResourceId: logAnalyticsWorkspaceResourceId
  }
]

/* -------------------------------------------------------------------------- */
/*                                  RESOURCES                                 */
/* -------------------------------------------------------------------------- */

resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
}

/* ----------------------------- Virtual Network ---------------------------- */

module virtualNetwork 'br/public:avm/res/network/virtual-network:0.1.8' = {
  name: take('${deployment().name}-virtual-network', 64)
  scope: resourceGroup
  params: {
    name: virtualNetworkName
    location: location
    tags: tags
    enableTelemetry: enableAvmTelemetry
    addressPrefixes: virtualNetworkAddressPrefixes
    dnsServers: dnsServers
    peerings: peerings
    subnets: subnets
    diagnosticSettings: diagnosticsSettings
  }
}

/* ------------------------- Netowrk Security Groups ------------------------ */

module privateEndpointsNetworkSecurityGroup 'br/public:avm/res/network/network-security-group:0.3.1' = {
  name: take('${deployment().name}-private-endpoints-nsg', 64)
  scope: resourceGroup
  params: {
    name: privateEndpointsNetworkSecurityGroupName
    location: location
    tags: tags
    enableTelemetry: enableAvmTelemetry
    securityRules: privateEndpointsNsgSecurityRules
    diagnosticSettings: diagnosticsSettings
  }
}

module jumpboxNetworkSecurityGroup 'br/public:avm/res/network/network-security-group:0.3.1' = {
  name: take('${deployment().name}-jumpbox-nsg', 64)
  scope: resourceGroup
  params: {
    name: jumpboxNetworkSecurityGroupName
    location: location
    tags: tags
    enableTelemetry: enableAvmTelemetry
    diagnosticSettings: diagnosticsSettings
  }
}

module frontDoorNetworkSecurityGroup 'br/public:avm/res/network/network-security-group:0.3.1' = {
  name: take('${deployment().name}-frontdoor-nsg', 64)
  scope: resourceGroup
  params: {
    name: frontDoorNetworkSecurityGroupName
    location: location
    tags: tags
    enableTelemetry: enableAvmTelemetry
    diagnosticSettings: diagnosticsSettings
  }
}

/* ------------------------------- Route Table ------------------------------ */

module aroRouteTable 'br/public:avm/res/network/route-table:0.2.3' = if (deployAroRouteTable) {
  name: take('${deployment().name}-aro-route-table', 64)
  scope: resourceGroup
  params: {
    name: aroRouteTableName
    location: location
    tags: tags
    enableTelemetry: enableAvmTelemetry
    routes: [
      {
        name: 'aro-to-internet'
        properties: {
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: firewallPrivateIpAddress!
          addressPrefix: '0.0.0.0/0'
        }
      }
    ]
  }
}

/* -------------------------------------------------------------------------- */
/*                                   OUTPUTS                                  */
/* -------------------------------------------------------------------------- */

@description('The name of the spoke resource group.')
output resourceGroupName string = resourceGroup.name

@description('The resource id of the spoke virtual network.')
output virtualNetworkResourceId string = virtualNetwork.outputs.resourceId

@description('The resource id of the master nodes subnet.')
output masterNodesSubnetResourceId string = virtualNetwork.outputs.subnetResourceIds[0]

@description('The resource id of the worker nodes subnet.')
output workerNodesSubnetResourceId string = virtualNetwork.outputs.subnetResourceIds[1]

@description('The resource id of the private endpoints subnet.')
output privateEndpointsSubnetResourceId string = virtualNetwork.outputs.subnetResourceIds[2]

@description('The resource id of the jumpbox subnet.')
output jumpboxSubnetResourceId string = virtualNetwork.outputs.subnetResourceIds[3]

@description('The resource id of the front door subnet.')
output frontDoorSubnetResourceId string = virtualNetwork.outputs.subnetResourceIds[4]

@description('The resource id of the private endpoints network security group.')
output routeTableResourceId string = deployAroRouteTable ? aroRouteTable.outputs.resourceId : ''
