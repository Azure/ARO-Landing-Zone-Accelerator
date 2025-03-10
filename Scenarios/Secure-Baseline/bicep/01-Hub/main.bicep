targetScope = 'subscription'

/* -------------------------------------------------------------------------- */
/*                                   IMPORTS                                  */
/* -------------------------------------------------------------------------- */

import {
  generateResourceName
  generateResourceNameFromParentResourceName
} from '../common-modules/naming/functions.bicep'

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

@description('The name of the resource group for the hub. Defaults to the naming convention `<abbreviation-resource-group>-<workload>-<lower-case-env>-<location-short>[-<hash>]`.')
param resourceGroupName string = generateResourceName('resourceGroup', workloadName, env, location, null, hash)

/* --------------------------------- Network -------------------------------- */

@description('The name of the virtual network for the hub. Defaults to the naming convention `<abbreviation-virtual-network>-<workload>-<lower-case-env>-<location-short>[-<hash>]`.')
param virtualNetworkName string = generateResourceName('virtualNetwork', workloadName, env, location, null, hash)

@description('The address prefixes for the hub virtual network. Defaults to ["10.1.0.0/16"].')
param virtualNetworkAddressPrefixes array = ['10.0.0.0/16']

@description('The DNS servers (Optional).')
param dnsServers array?

@description('The default subnet address prefix. Defaults to `10.0.0.0/24`.')
param defaultSubnetAddressPrefix string = '10.0.0.0/24'

@description('The name of the default subnet. Defaults to `default`.')
param defaultSubnetName string = 'default'

@description('The name of the default subnet network security group. Defaults to the naming convention `<abbreviation-nsg>-<default-subnet-name>[-<hash>]`.')
param defaultSubnetNetworkSecurityGroupName string = generateResourceNameFromParentResourceName('networkSecurityGroup', defaultSubnetName, null, hash)

@description('Additional subnets to add to the virtual network (Optional). Each object should contain name, addressPrefix, and optionally networkSecurityGroupResourceId.')
param additionalSubnets array? 

@description('The address prefix for the firewall subnet. Defaults to `10.0.1.0/26`.')
param firewallSubnetAddressPrefix string = '10.0.1.0/26'

@description('The address prefix for the firewall management subnet. Defaults to `10.0.2.0/26`.')
param firewallManagementSubnetAddressPrefix string = '10.0.2.0/26'

@description('The name of the public IP for the firewall. Defaults to the naming convention `<abbreviation-public-ip>-<firewall-name>[-<hash>]`.')
param firewallPublicIpName string = generateResourceNameFromParentResourceName('publicIp', firewallName, null, hash)

@description('The address prefix for the bastion subnet. Defaults to `10.0.3.0/27`.')
param bastionSubnetAddressPrefix string = '10.0.3.0/27'

@description('The name of the bastion subnet network security group. Defaults to the naming convention `<abbreviation-nsg>-AzureBastionSubnet[-<hash>]`.')
param bastionSubnetNetworkSecurityGroupName string = generateResourceNameFromParentResourceName('networkSecurityGroup', 'AzureBastionSubnet', null, hash)

@description('The name of the bastion public IP. Defaults to the naming convention `<abbreviation-public-ip>-<bastion-name>[-<hash>]`.')
param bastionPublicIpName string = generateResourceNameFromParentResourceName('publicIp', bastionName, null, hash)

@description('Link the key vault private DNS zone to the hub vnet. Defaults to false. This is required if a DNS resolver is deployed in the hub.')
param linkKeyvaultDnsZoneToHubVnet bool = false

@description('Link the ACR private DNS zone to the hub vnet. Defaults to false. This is required if a DNS resolver is deployed in the hub.')
param linkAcrDnsZoneToHubVnet bool = false

/* -------------------------------- Firewall -------------------------------- */

@description('The name of the firewall. Defaults to the naming convention `<abbreviation-firewall>-<workload>-<lower-case-env>-<location-short>[-<hash>]`.')
param firewallName string = generateResourceName('firewall', workloadName, env, location, null, hash)

@description('The availability zones for the firewall. Defaults to an array with all availability zones (1, 2 and 3).')
param firewallAvailabilityZone array = [ 1, 2, 3 ]

@description('The name of the firewall policy. Defaults to the naming convention `<abbreviation-firewall-policy>-<workload>-<lower-case-env>-<location-short>[-<hash>]`.')
param firewallPolicyName string = generateResourceName('firewallPolicy', workloadName, env, location, null, hash)

@description('The name of the firewall policy rule group. Defaults to the naming convention `<abbreviation-firewall-policy-rule-group>-<workload>-<lower-case-env>-<location-short>[-<hash>]`.')
param firewallPolicyRuleGroupName string = generateResourceName('firewallPolicyRuleGroup', workloadName, env, location, null, hash)

@description('Flag to deploy the firewall policy rule group for the sample app. Defaults to true. It uses the `afwp-rule-collection-groups-sample-app.jsonc` file.')
param deployFirewallPolicyRuleGroupSampleApp bool = true

/* --------------------------------- Bastion -------------------------------- */

@description('The name of the bastion. Defaults to the naming convention `<abbreviation-bastion>-<workload>-<lower-case-env>-<location-short>[-<hash>]`.')
param bastionName string = generateResourceName('bastion', workloadName, env, location, null, hash)

/* ------------------------------- Monitoring ------------------------------- */

@description('The name of the log analytics workspace. Defaults to the naming convention `<abbreviation-log-analytics>-<workload>-<lower-case-env>-<location-short>[-<hash>]`.')
param logAnalyticsWorkspaceName string = generateResourceName('logAnalyticsWorkspace', workloadName, env, location, null, hash)


/* -------------------------------------------------------------------------- */
/*                                  VARIABLES                                 */
/* -------------------------------------------------------------------------- */

/* ------------------------------- Netowrking ------------------------------- */

var bastionNSGSecurityRules = loadJsonContent('nsg/bastion-nsg.jsonc', 'securityRules')

// NSG for firewall subnets is not required
var defaultSubnets = [
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

var allSubnets = concat(defaultSubnets, additionalSubnets ?? [])

var keyVaultPrivateDnsZoneName = 'privatelink.vaultcore.azure.net'

var keyVaultPrivateDnsZoneVnetLinks = linkKeyvaultDnsZoneToHubVnet ? [
  {
    virtualNetworkResourceId: virtualNetwork.outputs.resourceId
  }
] : []

var acrPrivateDnsZoneName = 'privatelink${environment().suffixes.acrLoginServer}'

var acrPrivateDnsZoneVnetLinks = linkAcrDnsZoneToHubVnet ? [
  {
    virtualNetworkResourceId: virtualNetwork.outputs.resourceId
  }
] : []

/* -------------------------------- Firewall -------------------------------- */

var firewallPolicyRuleGroupFile = deployFirewallPolicyRuleGroupSampleApp ? loadJsonContent('firewall/afwp-rule-collection-groups-sample-app.jsonc') : loadJsonContent('firewall/afwp-rule-collection-groups-network-lockdown.jsonc')

var firewallPolicyRuleCollectionGroups = [ for ruleCollectionGroup in firewallPolicyRuleGroupFile : {
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
    addressPrefixes: virtualNetworkAddressPrefixes
    dnsServers: dnsServers
    subnets: allSubnets
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

/* -------------------------------- Firewall -------------------------------- */

module firewall 'br/public:avm/res/network/azure-firewall:0.4.0' = {
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
    threatIntelMode: 'Deny'
    azureSkuTier: 'Standard'
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
    tier: 'Standard'
    threatIntelMode: 'Alert'
    ruleCollectionGroups: firewallPolicyRuleCollectionGroups
    enableProxy: true
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
    virtualNetworkResourceId: virtualNetwork.outputs.resourceId
    publicIPAddressObject: {
      name: bastionPublicIpName
    }
    diagnosticSettings: diagnosticsSettings
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

/* ------------------------------- Telemetry ------------------------------- */
@description('Enable usage and telemetry feedback to Microsoft.')
var telemetryId = '1adc75a7-5143-4889-b19b-46b2d976020c-${location}'
module telemetry './telemetry.bicep' = {
  scope: resourceGroup
  name: 'telemetry'
  params: {
    enableTelemetry: enableAvmTelemetry
    telemetryId: telemetryId
  }
}

/* -------------------------------------------------------------------------- */
/*                                   OUTPUTS                                  */
/* -------------------------------------------------------------------------- */

@description('The name of the hub resource group.')
output resourceGroupName string = resourceGroup.name

@description('The resource id of the hub virtual network.')
output virtualNetworkResourceId string = virtualNetwork.outputs.resourceId

@description('The resource id of the log analytics workspace.')
output logAnalyticsWorkspaceResourceId string = logAnalyticsWorkspace.outputs.resourceId

@description('The resource id of the key vault private DNS zone.')
output keyVaultPrivateDnsZoneResourceId string = keyVaultPrivateDnsZone.outputs.resourceId

@description('The name of the key vault private DNS zone.')
output keyVaultPrivateDnsZoneName string = keyVaultPrivateDnsZone.outputs.name

@description('The resource id of the ACR private DNS zone.')
output acrPrivateDnsZoneResourceId string = containerRegistryPrivateDnsZone.outputs.resourceId

@description('The name of the ACR private DNS zone.')
output acrPrivateDnsZoneName string = containerRegistryPrivateDnsZone.outputs.name

@description('The private IP address of the firewall.')
output firewallPrivateIp string = firewall.outputs.privateIp
