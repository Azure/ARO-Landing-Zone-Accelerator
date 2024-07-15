targetScope = 'resourceGroup'

/* -------------------------------------------------------------------------- */
/*                                   IMPORTS                                  */
/* -------------------------------------------------------------------------- */

import { skuType as keyVaultSkuType } from './modules/key-vault/types.bicep'

import {
  getResourceName
  getResourceNameFromParentResourceName
  replaceSubnetNamePlaceholders
} from '../commonModules/naming/functions.bicep'

/* -------------------------------------------------------------------------- */
/*                                 PARAMETERS                                 */
/* -------------------------------------------------------------------------- */

@description('The name of the workload. Defaults to aro-lza.')
@minLength(3)
@maxLength(15)
param workloadName string = 'aro-lza'

@description('The location of the resources. Defaults to the deployment location.')
param location string = resourceGroup().location

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

/* ------------------------------- Networking ------------------------------- */

@description('The resource id of the subnet where the private endpoint will be created.')
param privateEndpointSubnetResourceId string

@description('The resource id of the private DNS zone for the key vault.')
param keyVaultPrivateDnsZoneResourceId string

/* -------------------------------- Key Vault ------------------------------- */

@description('The name of the key vault. Defaults to the naming convention `<abbreviation-key-vault>-<workloadName>-<lower-case-env>-<location-short>[-<hash>]`.')
param keyVaultName string = getResourceName('keyVault', workloadName, env, location, null, hash)

@description('The SKU of the key vault. Defaults to premium.')
param keyVaultSku keyVaultSkuType = 'premium'

@description('Enable purge protection. Defaults to true. If disk encryption set is enabled, this has to be set to `true` or the deployment of the ARO cluster will fail.')
param enablePurgeProtection bool = true

@description('The number of days tp retain soft deleted keys. Defaults to 90.')
@minValue(7)
@maxValue(90)
param softDeleteRetentionInDays int = 90

@description('Property to specify whether Azure Virtual Machines are permitted to retrieve certificates stored as secrets from the key vault. Defaults to false.')
param enableVaultForDeployment bool = false

@description('Property to specify whether Azure Resource Manager is permitted to retrieve secrets from the key vault. Defaults to false.')
param enableVaultForTemplateDeployment bool = false

@description('Property to specify whether Azure Disk Encryption is permitted to retrieve secrets from the key vault. Defaults to true.')
param enableVaultForDiskEncryption bool = true

// TODO add the keys and secret parameters
param keys array = []
param secrets array = []

@description('The name of the private endpoint for the key vault. Defaults to the naming convention `<abbreviation-private-endpoint>-<key-vault-name>`.')
param keyVaultPrivateEndpointName string = getResourceNameFromParentResourceName('privateEndpoint', keyVaultName, null, hash)

/* ------------------------------- Monitoring ------------------------------- */

@description('The Log Analytics workspace resource id. This is required to enable monitoring.')
param logAnalyticsWorkspaceResourceId string

/* -------------------------------------------------------------------------- */
/*                                  VARIABLES                                 */
/* -------------------------------------------------------------------------- */

/* -------------------------------- Key Vault ------------------------------- */

var keyVaultPrivateEndpoint = {
  name: keyVaultPrivateEndpointName
  subnetResourceId: privateEndpointSubnetResourceId
  privateDnsZoneResourceIds: [keyVaultPrivateDnsZoneResourceId]
}

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

/* -------------------------------- Key Vault ------------------------------- */

module keyVault 'br/public:avm/res/key-vault/vault:0.6.2' = {
  name: take('${deployment().name}-keyvault', 64)
  params: {
    name: keyVaultName
    location: location
    tags: tags
    enableTelemetry: enableAvmTelemetry
    sku: keyVaultSku
    enablePurgeProtection: enablePurgeProtection
    enableSoftDelete: true // Soft delete needs to be enabled: https://learn.microsoft.com/en-us/azure/key-vault/general/soft-delete-overview
    softDeleteRetentionInDays: softDeleteRetentionInDays
    publicNetworkAccess: 'Disabled'
    privateEndpoints: [keyVaultPrivateEndpoint]
    enableRbacAuthorization: true
    enableVaultForDeployment: enableVaultForDeployment
    enableVaultForTemplateDeployment: enableVaultForTemplateDeployment
    enableVaultForDiskEncryption: enableVaultForDiskEncryption
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
      ipRules: []
      virtualNetworkRules: []
    }
    keys: keys
    secrets: secrets
    diagnosticSettings: diagnosticsSettings
  }
}
