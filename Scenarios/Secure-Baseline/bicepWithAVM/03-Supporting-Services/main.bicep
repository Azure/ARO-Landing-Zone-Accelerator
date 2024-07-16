targetScope = 'resourceGroup'

/* -------------------------------------------------------------------------- */
/*                                   IMPORTS                                  */
/* -------------------------------------------------------------------------- */

import { skuType as keyVaultSkuType } from './modules/key-vault/types.bicep'
import { skuType as containerRegistrySkuType } from './modules/container-registry/types.bicep'
import { imageReferenceType, nicConfigurationType, osDiskType } from './modules/virtual-machine/types.bicep'

import {
  getResourceName
  getUniqueGlobalName
  getResourceNameFromParentResourceName
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

@description('The resource id of the subnet where the jump box will be created.')
param jumpBoxSubnetResourceId string

@description('The resource id of the private DNS zone for the key vault.')
param keyVaultPrivateDnsZoneResourceId string

@description('The resource id of the private DNS zone for the container registry.')
param containerRegistryDnsZoneResourceId string

/* -------------------------------- Key Vault ------------------------------- */

@description('The name of the key vault. Defaults to the naming convention `<abbreviation-key-vault><workloadName><lower-case-env><location-short>[<hash>]`.')
@minLength(3)
@maxLength(24)
param keyVaultName string = getUniqueGlobalName('keyVault', workloadName, env, location, null, hash, [resourceGroup().id], 5, 24, false)

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

/* -------------------------------- Container Registry ------------------------------------------ */

@minLength(5)
@maxLength(50)
@description('The name of the container registry. Defaults to the naming convention `<abbreviation-container-registry>-<workloadName>-<lower-case-env>-<location-short>[-<hash>]`.')
param containerRegistryName string = getUniqueGlobalName('containerRegistry', workloadName, env, location, null, hash, [resourceGroup().id], 5, 50, false)

@description('The SKU of the container registry. Defaults to Premium.')
param containerRegistrySku containerRegistrySkuType = 'Premium'

@description('The name of the private endpoint for the container registry. Defaults to the naming convention `<abbreviation-private-endpoint>-<container-registry-name>`.')
param containerRegistryPrivateEndpointName string = getResourceNameFromParentResourceName('privateEndpoint', containerRegistryName, null, hash)

/* ------------------------------- Windows Virtual Machine ------------------------------- */

@description('Flag to determine if the Windows VM should be deployed. Defaults to false.')
param deployWindowsJumpbox bool = false

@description('The name of the Windows virtual machine. Defaults to the naming convention `<abbreviation-virtual-machine><workloadName>-<lower-case-env>-<location-short>-win-mgmt[-<hash>]`.')
param windowsVMName string = getResourceName('virtualMachine', workloadName, env, location, 'win-mgmt', hash)

@description('The name of the Windows virtual machine computer. Defaults to the naming convention `<take(workloadName, 7)>-win-mgmt`.')
param windowsVMComputerName string = '${take(workloadName, 7)}-win-mgmt'

@description('The image reference for the Windows VM.')
param imageReferenceWindows imageReferenceType = {
  offer: 'WindowsServer'
  publisher: 'MicrosoftWindowsServer'
  sku: '2022-datacenter-azure-edition'
  version: 'latest'
}

@description('The size of the Windows virtual machine. Defaults to Standard_B2ms.')
param windowsVMSize string = 'Standard_B2ms'

@description('The username of the local administrator account for the Windows virtual machine. Defaults to WinAroAdminUsername.')
param windowsAdminUsername string = 'WinAroAdminUsername'

@description('The password for the local administrator account for the Windows virtual machine.')
@secure()
param windowsAdminPassword string

@description('The NIC configurations for the Windows virtual machine. Defaults to a single NIC configuration with the name `ipconfig01` and the subnet resource id of the jump box subnet.')
param windowsNicConfigurations nicConfigurationType[] = [
  {
    deleteOptions: 'Delete'
    ipConfigurations: [
      {
        name: 'ipconfig01'
        subnetResourceId: jumpBoxSubnetResourceId
      }
    ]
    nicSuffix: '-nic-01'
  }
]

@description('The OS disk configuration for the Windows virtual machine. Defaults to a managed disk with a storage account type of Standard_LRS.')
param windowsOsDiskConfiguration osDiskType = {
  createOption: 'FromImage'
  deleteOption: 'Delete'
  managedDisk: {
    storageAccountType: 'Standard_LRS'
  }
}

/* ------------------------------- Linux Virtual Machine ------------------------------- */

@description('Flag to determine if the Linux VM should be deployed. Defaults to false.')
param deployLinuxJumpbox bool = false

@minLength(1)
@maxLength(64)
@description('The name of the Linux virtual machine. Defaults to the naming convention `<abbreviation-virtual-machine><workloadName>-<lower-case-env>-<location-short>-lnx-mgmt[-<hash>]`.')
param linuxVMName string = getResourceName('virtualMachine', workloadName, env, location, 'lnx-mgmt', hash)

@description('The name of the Linux virtual machine computer. Defaults to the naming convention `<take(workloadName, 7)>-lnx-mgmt`.')
param linuxVMComputerName string = '${take(workloadName, 7)}-lnx-mgmt'

@description('The image reference for the Linux VM.')
param imageReferenceLinux imageReferenceType = {
  offer: '0001-com-ubuntu-server-jammy'
  publisher: 'Canonical'
  sku: '22_04-lts-gen2'
  version: 'latest'
}

@description('The size of the Linux virtual machine. Defaults to Standard_B2ms.')
param linuxVMSize string = 'Standard_B2ms'

@description('The username of the local administrator account for the Linux virtual machine. Defaults to LnxAroAdminUsername.')
param linuxAdminUsername string = 'LnxAroAdminUsername'

@description('The password for the local administrator account for the Linux virtual machine.')
@secure()
param linuxAdminPassword string

@description('The NIC configurations for the Linux virtual machine. Defaults to a single NIC configuration with the name `ipconfig01` and the subnet resource id of the jump box subnet.')
param linuxNicConfigurations nicConfigurationType[] = [
  {
    deleteOptions: 'Delete'
    ipConfigurations: [
      {
        name: 'ipconfig01'
        subnetResourceId: jumpBoxSubnetResourceId
      }
    ]
    nicSuffix: '-nic-01'
  }
]

@description('The OS disk configuration for the Linux virtual machine. Defaults to a managed disk with a storage account type of Standard_LRS.')
param linuxOsDiskConfiguration osDiskType = {
  createOption: 'FromImage'
  deleteOption: 'Delete'
  managedDisk: {
    storageAccountType: 'Standard_LRS'
  }
}

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

/* -------------------------------- Container Registry ------------------------------- */

var containerRegistryEndpoint = {
  name: containerRegistryPrivateEndpointName
  subnetResourceId: privateEndpointSubnetResourceId
  privateDnsZoneResourceIds: [containerRegistryDnsZoneResourceId]
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

/* ------------------------------- Virtual Machine ------------------------------- */

// Windows VM Module
module windowsVM 'br/public:avm/res/compute/virtual-machine:0.5.3' = if (deployWindowsJumpbox) {
  name: take('${deployment().name}-windows-vm', 64)
  params: {
    name: windowsVMName
    location: location
    tags: tags
    enableTelemetry: enableAvmTelemetry
    vmSize: windowsVMSize
    osType: 'Windows'
    computerName: windowsVMComputerName
    imageReference: imageReferenceWindows
    zone: 0
    adminUsername: windowsAdminUsername
    adminPassword: windowsAdminPassword
    nicConfigurations: windowsNicConfigurations
    osDisk: windowsOsDiskConfiguration
  }
}

// Linux VM Module
module linuxVM 'br/public:avm/res/compute/virtual-machine:0.5.3' = if (deployLinuxJumpbox) {
  name: take('${deployment().name}-linux-vm', 64)
  params: {
    name: linuxVMName
    location: location
    tags: tags
    enableTelemetry: enableAvmTelemetry
    vmSize: linuxVMSize
    osType: 'Linux'
    computerName: linuxVMComputerName
    imageReference: imageReferenceLinux
    zone: 0
    adminUsername: linuxAdminUsername
    adminPassword: linuxAdminPassword
    nicConfigurations: linuxNicConfigurations
    osDisk: linuxOsDiskConfiguration
  }
}

/* -------------------------------- Container Registry ------------------------------------------ */

module registry 'br/public:avm/res/container-registry/registry:0.3.1' = {
  name: 'registryDeployment'
  params: {
    name: containerRegistryName
    location: location
    tags: tags
    enableTelemetry: enableAvmTelemetry
    acrSku: containerRegistrySku
    publicNetworkAccess: 'Disabled'
    privateEndpoints: [containerRegistryEndpoint]
  }
}
