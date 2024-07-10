targetScope = 'subscription'

/* -------------------------------------------------------------------------- */
/*                                   IMPORTS                                  */
/* -------------------------------------------------------------------------- */

import {
  getResourceName
  getResourceNameFromParentResourceName
} from '../commonModules/naming/functions.bicep'

/* -------------------------------------------------------------------------- */
/*                                 PARAMETERS                                 */
/* -------------------------------------------------------------------------- */

@description('The name of the workload. Defaults to hub.')
@minLength(3)
@maxLength(15)
param workloadName string = 'hub'

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

@description('Enable Azure Verified Modules (AVM) telemetry. Defaults to false.')
param enableAvmTelemetry bool = true

@description('The name of the resource group for the hub.')
param resourceGroupName string = getResourceName('rg', workloadName, env, hash)

/* --------------------------------- Network -------------------------------- */

@description('The name of the virtual network for the hub.')
param virtualNetworkName string = getResourceName('vnet', workloadName, env, hash)

@description('The CIDR for the virtual network. Defaults to `10.0.0.0/16`.')
param virtualNetworkAddressPrefix string = '10.0.0.0/16'

@description('The DNS servers (Optional).')
param dnsServers array?

@description('The default subnet address prefix. Defaults to `10.0.0.0/24`.')
param defaultSubnetAddressPrefix string = '10.0.0.0/24'

@description('The name of the default subnet.')
param defaultSubnetName string = 'default'

@description('The name of the default subnet network security group.')
param defaultSubnetNetworkSecurityGroupName string = getResourceNameFromParentResourceName('nsg', defaultSubnetName)

@description('The address prefix for the firewall subnet. Defaults to `10.0.1.0/26`.')
param firewallSubnetAddressPrefix string = '10.0.1.0/26'

@description('The address prefix for the firewall management subnet. Defaults to `10.0.2.0/26`.')
param firewallManagementSubnetAddressPrefix string = '10.0.2.0/26'

@description('The address prefix for the bastion subnet. Defaults to `10.0.3.0/27`.')
param bastionSubnetAddressPrefix string = '10.0.3.0/27'

@description('The name of the bastion subnet network security group.')
param bastionSubnetNetworkSecurityGroupName string = getResourceNameFromParentResourceName('nsg', 'AzureBastionSubnet')

@description('The name of the public IP for the firewall.')
param firewallPublicIpName string = getResourceNameFromParentResourceName('pip', firewallName)

@description('The name of the public IP for the firewall management.')
param firewallManagementPublicIpName string = getResourceNameFromParentResourceName('pip', '${firewallName}-mgmt')

@description('Link the key vault private DNS zone to the hub vnet. Defaults to false. This is required if a DNS resolver is deployed in the hub.')
param linkKeyvaultDnsZoneToHubVnet bool = false

@description('Link the ACR private DNS zone to the hub vnet. Defaults to false. This is required if a DNS resolver is deployed in the hub.')
param linkAcrDnsZoneToHubVnet bool = false

/* -------------------------------- Firewall -------------------------------- */

@description('The name of the firewall.')
param firewallName string = getResourceName('afw', workloadName, env, hash)

@description('The availability zones for the firewall. Defaults to an array with all availability zones (1, 2 and 3).')
param firewallAvailabilityZone array = [ 1, 2, 3 ]

@description('The name of the firewall policy.')
param firewallPolicyName string = getResourceName('afwp', workloadName, env, hash)

@description('The name of the firewall policy rule group.')
param firewallPolicyRuleGroupName string = getResourceName('afwprg', workloadName, env, hash)

/* --------------------------------- Bastion -------------------------------- */

@description('The name of the bastion.')
param bastionName string = getResourceName('bas', workloadName, env, hash)

/* ------------------------------- Monitoring ------------------------------- */

param logAnalyticsWorkspaceName string = getResourceName('log', workloadName, env, hash)


/* -------------------------------------------------------------------------- */
/*                                  VARIABLES                                 */
/* -------------------------------------------------------------------------- */

/* ------------------------------- Netowrking ------------------------------- */

var bastionNSGSecurityRules = loadJsonContent('nsg/bastion-nsg.jsonc', 'securityRules')

// NSG for firewall subnets is not required
var subnets = [
  {
    name: defaultSubnetName
    addressPrefix: defaultSubnetAddressPrefix
    networkSecurityGroupResourceId: defaultSubnetNetworkSecurityGroup.outputs.resourceId
  }
  {
    name: 'AzureFirewallSubnet'
    addressPrefix: firewallSubnetAddressPrefix
  }
  {
    name: 'AzureFirewallManagementSubnet'
    addressPrefix: firewallManagementSubnetAddressPrefix
  }
  {
    name: 'AzureBastionSubnet'
    addressPrefix: bastionSubnetAddressPrefix
    networkSecurityGroupResourceId: bastionSubnetNetworkSecurityGroup.outputs.resourceId
  }
]

var keyVaultPrivateDnsZoneName = 'private${environment().suffixes.keyvaultDns}'

var keyVaultPrivateDnsZoneVnetLinks = linkKeyvaultDnsZoneToHubVnet ? [
  {
    virtualNetworkResourceId: virtualNetwork.outputs.resourceId
  }
] : []

var acrPrivateDnsZoneName = 'private${environment().suffixes.acrLoginServer}'

var acrPrivateDnsZoneVnetLinks = linkAcrDnsZoneToHubVnet ? [
  {
    virtualNetworkResourceId: virtualNetwork.outputs.resourceId
  }
] : []

/* -------------------------------- Firewall -------------------------------- */

var firewallPolicyRuleCollectionGroups = [ for ruleCollectionGroup in loadJsonContent('firewall/afwp-rule-collection-groups.jsonc') : {
  name: ruleCollectionGroup.name == '<FIREWALL_POLICY_RULE_GROUP_NAME_PLACEHOLDER>' ? firewallPolicyRuleGroupName : ruleCollectionGroup.name
  priority: ruleCollectionGroup.priority
  ruleCollections: ruleCollectionGroup.ruleCollections
}]

/* ------------------------------- Monitoring ------------------------------- */

var diagnosticsSettings = [ 
  {
    logAnalyticsDestinationType: 'AzureDiagnostics'
    workspaceResourceId: logAnalyticsWorkspace.outputs.resourceId
  }
]

/* -------------------------------------------------------------------------- */
/*                                  RESOURCES                                 */
/* -------------------------------------------------------------------------- */

resource resourceGroup 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

/* ------------------------------- Networking ------------------------------- */

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
    subnets: subnets
    diagnosticSettings: diagnosticsSettings
  }
}

module defaultSubnetNetworkSecurityGroup 'br/public:avm/res/network/network-security-group:0.3.1' = {
  name: take('${deployment().name}-default-nsg', 64)
  scope: resourceGroup
  params: {
    name: defaultSubnetNetworkSecurityGroupName
    location: location
    tags: tags
    enableTelemetry: enableAvmTelemetry
    securityRules: []
    diagnosticSettings: diagnosticsSettings
  }
}

module bastionSubnetNetworkSecurityGroup 'br/public:avm/res/network/network-security-group:0.3.1' = {
  name: take('${deployment().name}-bastion-nsg', 64)
  scope: resourceGroup
  params: {
    name: bastionSubnetNetworkSecurityGroupName
    location: location
    tags: tags
    enableTelemetry: enableAvmTelemetry
    securityRules: bastionNSGSecurityRules
    diagnosticSettings: diagnosticsSettings
  }
}

module keyVaultPrivateDnsZone 'br/public:avm/res/network/private-dns-zone:0.3.1' = {
  name: take('${deployment().name}-kv-private-dns-zone', 64)
  scope: resourceGroup
  params: {
    name: keyVaultPrivateDnsZoneName
    location: 'global'
    tags: tags
    enableTelemetry: enableAvmTelemetry
    virtualNetworkLinks: keyVaultPrivateDnsZoneVnetLinks
  }
}

module containerRegistryPrivateDnsZone 'br/public:avm/res/network/private-dns-zone:0.3.1' = {
  name: take('${deployment().name}-acr-private-dns-zone', 64)
  scope: resourceGroup
  params: {
    name: acrPrivateDnsZoneName
    location: 'global'
    tags: tags
    enableTelemetry: enableAvmTelemetry
    virtualNetworkLinks: acrPrivateDnsZoneVnetLinks
  }
}

// This public IP address is required because of this bug in AVM module: https://github.com/Azure/bicep-registry-modules/issues/2589
module firewallManagementPublicIp 'br/public:avm/res/network/public-ip-address:0.4.2' = {
  name: take('${deployment().name}-firewall-management-public-ip', 64)
  scope: resourceGroup
  params: {
    name: firewallManagementPublicIpName
    location: location
    tags: tags
    enableTelemetry: enableAvmTelemetry
    publicIPAllocationMethod: 'Static'
    skuName: 'Standard'
    skuTier: 'Regional'
    zones: firewallAvailabilityZone
    diagnosticSettings: diagnosticsSettings
  }
}

/* -------------------------------- Firewall -------------------------------- */

module firewall 'br/public:avm/res/network/azure-firewall:0.3.0' = {
  name: take('${deployment().name}-firewall', 64)
  scope: resourceGroup
  params: {
    name: firewallName
    location: location
    tags: tags
    enableTelemetry: enableAvmTelemetry
    virtualNetworkResourceId: virtualNetwork.outputs.resourceId
    publicIPAddressObject: {
      name: firewallPublicIpName
    }
    managementIPResourceID: firewallManagementPublicIp.outputs.resourceId
    threatIntelMode: 'Deny'
    azureSkuTier: 'Basic'
    zones: firewallAvailabilityZone
    firewallPolicyId: firewallPolicy.outputs.resourceId
    applicationRuleCollections: []
    natRuleCollections: []
    networkRuleCollections: []
    diagnosticSettings: diagnosticsSettings
  }
}

module firewallPolicy 'br/public:avm/res/network/firewall-policy:0.1.3' = {
  name: take('${deployment().name}-firewall-policy', 64)
  scope: resourceGroup
  params: {
    name: firewallPolicyName
    location: location
    tags: tags
    enableTelemetry: enableAvmTelemetry
    tier: 'Basic'
    threatIntelMode: 'Alert'
    ruleCollectionGroups: firewallPolicyRuleCollectionGroups
  }
}

/* --------------------------------- Bastion -------------------------------- */

module bastion 'br/public:avm/res/network/bastion-host:0.2.2' = {
  name: take('${deployment().name}-bastion', 64)
  scope: resourceGroup
  params: {
    name: bastionName
    location: location
    tags: tags
    enableTelemetry: enableAvmTelemetry
    diagnosticSettings: diagnosticsSettings
    virtualNetworkResourceId: virtualNetwork.outputs.resourceId
  }
}

/* ------------------------------- Monitoring ------------------------------- */

module logAnalyticsWorkspace 'br/public:avm/res/operational-insights/workspace:0.4.0' = {
  name: take('${deployment().name}-log-analytics-workspace', 64)
  scope: resourceGroup
  params: {
    name: logAnalyticsWorkspaceName
    location: location
    tags: tags
    enableTelemetry: enableAvmTelemetry
  }
} 

/* -------------------------------------------------------------------------- */
/*                                   OUTPUTS                                  */
/* -------------------------------------------------------------------------- */

@description('The resource id of the hub virtual network.')
output hubVirtualNetworkId string = virtualNetwork.outputs.resourceId

@description('The resource id of the log analytics workspace.')
output logAnalyticsWorkspaceId string = logAnalyticsWorkspace.outputs.resourceId

@description('The resource id of the key vault private DNS zone.')
output keyVaultPrivateDnsZoneId string = keyVaultPrivateDnsZone.outputs.resourceId

@description('The resource id of the ACR private DNS zone.')
output acrPrivateDnsZoneId string = containerRegistryPrivateDnsZone.outputs.resourceId

@description('The private IP address of the firewall.')
output firewallPrivateIp string = firewall.outputs.privateIp
