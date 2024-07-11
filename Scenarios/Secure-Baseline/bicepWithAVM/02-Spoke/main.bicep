targetScope = 'subscription'

/* -------------------------------------------------------------------------- */
/*                                   IMPORTS                                  */
/* -------------------------------------------------------------------------- */

import {
  getResourceName
  getResourceNameFromParentResourceName
  replaceSubnetNamePlaceholders
} from '../commonModules/naming/functions.bicep'

import { 
  subnetConfigType 
} from '../commonModules/network/types.bicep'

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
@description('The hash to be added to every resource, configuration and exemption name. If not set, a unique string is generated for resources with global name based on its resource group id. The size of the hash is 5 characters.')
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
param resourceGroupName string = getResourceName('resourceGroup', workloadName, env, location, null, hash)

/* ----------------------------- Virtual Network ---------------------------- */

@description('The resource id of the hub virtual network. This is required to peer the spoke virtual network with the hub virtual network.')
param hubVirtualNetworkId string

@description('The name of the spoke virtual network. Defaults to the naming convention `<abbreviation-virtual-network>-<workload>-<lower-case-env>-<location-short>[-<hash>]`.')
@minLength(1)
@maxLength(64)
param virtualNetworkName string = getResourceName('virtualNetwork', workloadName, env, location, null, hash)

@description('The CIDR for the spoke virtual network. Defaults to 10.1.0.0/16.')
param virtualNetworkAddressPrefix string = '10.1.0.0/16'

@description('The DNS server array (Optional).')
param dnsServers array?

/* --------------------------- Master Nodes Subnet -------------------------- */

@description('The name of the master nodes subnet. Defaults to the naming convention `<abbreviation-subnet>-aro-master-<workloadName>-<lower-case-env>-<location-short>[-<hash>]`.')
@minLength(1)
@maxLength(80)
param masterNodesSubnetName string = getResourceName('subnet', 'aro-master-${workloadName}', env, location, null, hash)

@description('The CIDR for the master nodes subnet. Defaults to 10.1.0.0/23.')
param masterNodesSubnetAddressPrefix string = '10.1.0.0/23'

/* --------------------------- Worker Nodes Subnet -------------------------- */

@description('The name of the worker nodes subnet. Defaults to the naming convention `<abbreviation-subnet>-aro-worker-<workloadName>-<lower-case-env>-<location-short>[-<hash>]`.')
@minLength(1)
@maxLength(80)
param workerNodesSubnetName string = getResourceName('subnet', 'aro-worker-${workloadName}', env, location, null, hash)

@description('The CIDR for the worker nodes subnet. Defaults to 10.1.2.0/23.')
param workerNodesSubnetAddressPrefix string = '10.1.2.0/23'

/* ------------------------ Private Endpoints Subnet ------------------------ */

@description('The name of the private endpoints subnet. Defaults to the naming convention `<abbreviation-subnet>-pep-<workloadName>-<lower-case-env>-<location-short>[-<hash>]`.')
@minLength(1)
@maxLength(80)
param privateEndpointsSubnetName string = getResourceName('subnet', 'pep-${workloadName}', env, location, null, hash)

@description('The CIDR for the private endpoints subnet. Defaults to 10.1.4.0/24.')
param privateEndpointsSubnetAddressPrefix string = '10.1.4.0/24'

@description('The name of the network security group for the private endpoints subnet. Defaults to the naming convention `<abbreviation-nsg>-<privateEndpointsSubnetName>`.')
param privateEndpointsNetworkSecurityGroupName string = getResourceNameFromParentResourceName('networkSecurityGroup', privateEndpointsSubnetName, null, hash)

/* ----------------------------- Jumpbox Subnet ----------------------------- */

@description('The name of the jumpbox subnet. Defaults to the naming convention `<abbreviation-subnet>-jumpbox-<workloadName>-<lower-case-env>-<location-short>[-<hash>]`.')
@minLength(1)
@maxLength(80)
param jumpboxSubnetName string = getResourceName('subnet', 'jumpbox-${workloadName}', env, location, null, hash)

@description('The CIDR for the jumpbox subnet. Defaults to 10.1.5.0/24')
param jumpboxSubnetAddressPrefix string = '10.1.5.0/24'

@description('The name of the network security group for the jumpbox subnet. Defaults to the naming convention `<abbreviation-nsg>-<jumpboxSubnetName>`.')
param jumpboxNetworkSecurityGroupName string = getResourceNameFromParentResourceName('networkSecurityGroup', jumpboxSubnetName, null, hash)

/* ------------------------------ Other Subnets ----------------------------- */

@description('The configuration for other subnets. Defaults to an empty array.')
param otherSubnetsConfig subnetConfigType

/* ------------------------------- Route Table ------------------------------ */

@description('The name of the route table for the two ARO subnets. Defaults to the naming convention `<abbreviation-route-table>-aro-<lower-case-env>-<location-short>[-<hash>]`.')
param aroRouteTableName string = getResourceName('routeTable', 'aro', env, location, null, hash)

@description('The private IP address of the firewall to route ARO egress traffic to it (Optional). If not provided, the route table will not be created and not associated with the worker nodes and master nodes subnets.')
param firewallPrivateIpAddress string?

/* ------------------------------- Monitoring ------------------------------- */

@description('The Log Analytics workspace id. This is required to enable monitoring.')
param logAnalyticsWorkspaceId string

/* -------------------------------------------------------------------------- */
/*                                  VARIABLES                                 */
/* -------------------------------------------------------------------------- */

var deployAroRouteTable = firewallPrivateIpAddress != null

/* --------------------------------- Peering -------------------------------- */

var hubVirtualNetworkName = last(split(hubVirtualNetworkId, '/'))

var remotePeeringName = '${hubVirtualNetworkName}-to-${virtualNetworkName}-peering'

var peerings = [
  {
    name: '${virtualNetworkName}-to-${hubVirtualNetworkName}-peering'
    remotePeeringEnabled: true
    remotePeeringName: remotePeeringName
    remoteVirtualNetworkId: hubVirtualNetworkId
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
]


  var otherSubnets = [for subnet in otherSubnetsConfig.subnets: {
    name: replaceSubnetNamePlaceholders(subnet.name, workloadName, env)
    addressPrefix: subnet.addressPrefix
  }]

var subnets = concat(predefinedSubnets, otherSubnets)

/* ------------------------------- Monitoring ------------------------------- */

var diagnosticsSettings = [
  {
    logAnalyticsDestinationType: 'AzureDiagnostics'
    workspaceResourceId: logAnalyticsWorkspaceId
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
    addressPrefixes: [virtualNetworkAddressPrefix]
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
