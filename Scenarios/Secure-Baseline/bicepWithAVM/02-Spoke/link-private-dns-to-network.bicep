targetScope = 'resourceGroup'

/* -------------------------------------------------------------------------- */
/*                                   IMPORTS                                  */
/* -------------------------------------------------------------------------- */

import { generateResourceNameFromParentResourceName } from '../common-modules/naming/functions.bicep'

/* -------------------------------------------------------------------------- */
/*                                 PARAMETERS                                 */
/* -------------------------------------------------------------------------- */

@description('The name of the workload. Defaults to hub.')
@minLength(3)
@maxLength(15)
param workloadName string = 'aro-lza'

@description('The location of the private link. Defaults to global')
param location string = 'global'

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

@description('The name of the virtual network link.')
param virtualNetworkLinkName string = generateResourceNameFromParentResourceName('virtualNetworkLink', last(split(virtualNetworkResourceId, '/')), null, hash)

@description('The name of the private DNS zone.')
param privateDnsZoneName string

@description('The resource id of the virtual network to link the private DNS zone to.')
param virtualNetworkResourceId string

@description('Indicate if auto-registration of virtual machine records in the virtual network in the Private DNS zone is enabled. Defaults to false.')
param registrationEnabled bool = false

/* -------------------------------------------------------------------------- */
/*                                  RESOURCES                                 */
/* -------------------------------------------------------------------------- */

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: privateDnsZoneName
}

resource virtualNetworkLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: virtualNetworkLinkName
  parent: privateDnsZone
  location: location
  tags: tags
  properties: {
    registrationEnabled: registrationEnabled
    virtualNetwork: {
      id: virtualNetworkResourceId
    }
  }
}
