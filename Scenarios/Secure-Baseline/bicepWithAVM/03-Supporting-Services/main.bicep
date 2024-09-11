targetScope = 'resourceGroup'

/* -------------------------------------------------------------------------- */
/*                                   IMPORTS                                  */
/* -------------------------------------------------------------------------- */

import { skuType as keyVaultSkuType, keyType, secretType } from './modules/key-vault/types.bicep'
import { skuType as containerRegistrySkuType } from './modules/container-registry/types.bicep'
import { imageReferenceType, nicConfigurationType, osDiskType } from './modules/virtual-machine/types.bicep'

import {
  generateResourceName
  generateUniqueGlobalName
  generateResourceNameFromParentResourceName
} from '../common-modules/naming/functions.bicep'

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
param acrPrivateDnsZoneResourceId string

/* -------------------------------- Key Vault ------------------------------- */

@description('The name of the key vault. Defaults to the naming convention `<abbreviation-key-vault><workload-name><lower-case-env><location-short>[<hash>]`.')
@minLength(3)
@maxLength(24)
param keyVaultName string = generateUniqueGlobalName('keyVault', workloadName, env, location, null, hash, [resourceGroup().id], 5, 24, false)

@description('The SKU of the key vault. Defaults to premium.')
param keyVaultSku keyVaultSkuType = 'premium'

@description('Enable purge protection. Defaults to true. If disk encryption set is enabled, it is set to true as it is required by the cluster.')
param enablePurgeProtection bool = true || deployDiskEncryptionSet

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

@description('The key to be created in the key vault. Defaults to an empty array. If deployDiskEncryptionSet is set to true, a key for disk encryption set will be created.')
param keys keyType[] = []

@description('The name of the private endpoint for the key vault. Defaults to the naming convention `<abbreviation-private-endpoint>-<key-vault-name>`.')
param keyVaultPrivateEndpointName string = generateResourceNameFromParentResourceName('privateEndpoint', keyVaultName, null, hash)

@description('The secrets to be created in the key vault. Defaults to an empty array.')
param secrets secretType[] = []

/* --------------------------- Disk Encryption Set -------------------------- */

@description('Flag to determine if the disk encryption set should be deployed. Defaults to false.')
param deployDiskEncryptionSet bool = true

@description('The name of the disk encryption set. Defaults to the naming convention `<abbreviation-disk-encryption-set>-<workloadName>-<lower-case-env>-<location-short>-[-<hash>]`.')
param diskEncryptionSetName string = generateResourceName('diskEncryptionSet', workloadName, env, location, null, hash)

@description('The name of the user managed identity to access the key vault for the disk encryption set. Defaults to the naming convention `<abbreviation-user-managed-identity>-<disk-encryption-set-name>[-<hash>]`.')
@minLength(3)
@maxLength(128)
param userManagedIdentityToAccessDiskEncryptionSetKeyName string = generateResourceNameFromParentResourceName('userManagedIdentity', diskEncryptionSetName, null, hash)

@description('The type of encryption to be used for the disk encryption set. Defaults to `EncryptionAtRestWithCustomerKey`. Currently `ConfidentialVmEncryptedWithCustomerKey` is not supported by the AVM template.')
@allowed([
  'EncryptionAtRestWithCustomerKey'
  'EncryptionAtRestWithPlatformAndCustomerKeys'
])
param diskEncryptionSetEncryptionType string = 'EncryptionAtRestWithCustomerKey'

@description('The key to be created in the key vault for the disk encryption set. Defaults to an empty array.')
param diskEncryptionSetKey keyType = {
  name: generateResourceNameFromParentResourceName('keyVaultKey', diskEncryptionSetName, null, hash)
  kty: 'RSA'
  keySize: 2048
  rotationPolicy: {
    attributes: {
      expiryTime: 'P2Y'
    }
    lifetimeActions: [
      {
        action: {
          type: 'Rotate'
        }
        trigger: {
          timeBeforeExpiry: 'P2M'
        }
      }
      {
        action: {
          type: 'Notify'
        }
        trigger: {
          timeBeforeExpiry: 'P30D'
        }
      }
    ]
  }
}

/* -------------------------------- Container Registry ------------------------------------------ */

@description('The name of the container registry. Defaults to the naming convention `<abbreviation-container-registry>-<workloadName>-<lower-case-env>-<location-short>[-<hash>]`.')
@minLength(5)
@maxLength(50)
param containerRegistryName string = generateUniqueGlobalName('containerRegistry', workloadName, env, location, null, hash, [resourceGroup().id], 5, 50, false)

@description('The SKU of the container registry. Defaults to Premium.')
param containerRegistrySku containerRegistrySkuType = 'Premium'

@description('The name of the private endpoint for the container registry. Defaults to the naming convention `<abbreviation-private-endpoint>-<container-registry-name>`.')
param containerRegistryPrivateEndpointName string = generateResourceNameFromParentResourceName('privateEndpoint', containerRegistryName, null, hash)

/* ------------------------------- Windows Virtual Machine ------------------------------- */

@description('Flag to determine if the Windows VM should be deployed. Defaults to true.')
param deployWindowsJumpbox bool = true

@description('The name of the Windows virtual machine. Defaults to the naming convention `<abbreviation-virtual-machine><workloadName>-<lower-case-env>-<location-short>-win-jbx[-<hash>]`.')
param windowsVMName string = generateResourceName('virtualMachine', workloadName, env, location, 'win-jbx', hash)

@description('The name of the Windows virtual machine computer. Defaults to the naming convention `<take(workloadName, 7)>-win-jbx`.')
param windowsVMComputerName string = '${take(workloadName, 7)}-win-jbx'

@description('The image reference for the Windows VM.')
param imageReferenceWindows imageReferenceType = {
  offer: 'WindowsServer'
  publisher: 'MicrosoftWindowsServer'
  sku: '2022-datacenter-azure-edition'
  version: 'latest'
}

@description('The size of the Windows virtual machine. Defaults to Standard_B2ms.')
param windowsVMSize string = 'Standard_B2ms'

@description('The username of the local administrator account for the Windows virtual machine. Defaults to arolzauser.')
param windowsAdminUsername string = 'arolzauser'

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
    enableAcceleratedNetworking: false
  }
]

@description('The OS disk configuration for the Windows virtual machine. Defaults to a managed disk with a storage account type of Standard_LRS.')
param windowsOsDiskConfiguration osDiskType = {
  createOption: 'FromImage'
  deleteOption: 'Delete'
  managedDisk: {
    storageAccountType: 'Standard_LRS'
  }
  diskSizeGB: 128
}

/* ------------------------------- Linux Virtual Machine ------------------------------- */

@description('Flag to determine if the Linux VM should be deployed. Defaults to true.')
param deployLinuxJumpbox bool = true

@minLength(1)
@maxLength(64)
@description('The name of the Linux virtual machine. Defaults to the naming convention `<abbreviation-virtual-machine><workloadName>-<lower-case-env>-<location-short>-lnx-jbx[-<hash>]`.')
param linuxVMName string = generateResourceName('virtualMachine', workloadName, env, location, 'lnx-jbx', hash)

@description('The name of the Linux virtual machine computer. Defaults to the naming convention `<take(workloadName, 7)>-lnx-jbx`.')
param linuxVMComputerName string = '${take(workloadName, 7)}-lnx-jbx'

@description('The image reference for the Linux VM.')
param imageReferenceLinux imageReferenceType = {
  offer: '0001-com-ubuntu-server-jammy'
  publisher: 'Canonical'
  sku: '22_04-lts-gen2'
  version: 'latest'
}

@description('The size of the Linux virtual machine. Defaults to Standard_B2ms.')
param linuxVMSize string = 'Standard_B2ms'

@description('The username of the local administrator account for the Linux virtual machine. Defaults to arolzauser.')
param linuxAdminUsername string = 'arolzauser'

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
    enableAcceleratedNetworking: false
  }
]

@description('The OS disk configuration for the Linux virtual machine. Defaults to a managed disk with a storage account type of Standard_LRS.')
param linuxOsDiskConfiguration osDiskType = {
  createOption: 'FromImage'
  deleteOption: 'Delete'
  managedDisk: {
    storageAccountType: 'Standard_LRS'
  }
  diskSizeGB: 128
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

var _keys = deployDiskEncryptionSet ? concat([diskEncryptionSetKey], keys) : keys

/* -------------------------------- Container Registry ------------------------------- */

var containerRegistryEndpoint = {
  name: containerRegistryPrivateEndpointName
  subnetResourceId: privateEndpointSubnetResourceId
  privateDnsZoneResourceIds: [acrPrivateDnsZoneResourceId]
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
    keys: _keys
    secrets: secrets
    diagnosticSettings: diagnosticsSettings
  }
}

/* --------------------------- Disk Encryption Set -------------------------- */

module diskEncryptionSetForAroUserManagedIdentity 'br/public:avm/res/managed-identity/user-assigned-identity:0.2.2' = if (deployDiskEncryptionSet)  {
  name: take('${deployment().name}-umi-for-disk-encryption-set', 64)
  params: {
    name: userManagedIdentityToAccessDiskEncryptionSetKeyName!
    location: location
    tags: tags
    enableTelemetry: enableAvmTelemetry
  }
}

module diskEncryptionSetForAro 'br/public:avm/res/compute/disk-encryption-set:0.1.5' = if (deployDiskEncryptionSet) {
  name: take('${deployment().name}-disk-encryption-set', 64)
  params: {
    name: diskEncryptionSetName!
    location: location
    tags: tags
    enableTelemetry: enableAvmTelemetry
    keyVaultResourceId: keyVault.outputs.resourceId
    keyName: diskEncryptionSetKey.name
    encryptionType: diskEncryptionSetEncryptionType
    managedIdentities: {
      systemAssigned: false
      userAssignedResourceIds: [diskEncryptionSetForAroUserManagedIdentity.outputs.resourceId]
    }
  }
}

/* --------------------------- Container Registry --------------------------- */

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
    acrAdminUserEnabled: true
    anonymousPullEnabled: false
  }
}

/* ------------------------------- Jumpbox VMs ------------------------------ */

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

module linuxVM 'br/public:avm/res/compute/virtual-machine:0.6.0' = if (deployLinuxJumpbox) {
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
    extensionCustomScriptConfig:{
      enabled: true 
      fileData:[
        {
          uri: 'https://raw.githubusercontent.com/Azure/ARO-Landing-Zone-Accelerator/main/Scenarios/Secure-Baseline/bicepWithAVM/vm-scripts/linux/install_packages.sh'
        }
      ]
    }
    extensionCustomScriptProtectedSetting: {
      commandToExecute: 'bash install_packages.sh'
    }
  }
}

/* -------------------------------------------------------------------------- */
/*                                   OUTPUTS                                  */
/* -------------------------------------------------------------------------- */

@description('The resource id of the key vault.')
output diskEncryptionSetResourceId string = deployDiskEncryptionSet ? diskEncryptionSetForAro.outputs.resourceId : ''

@description('The name of the linux jumpbox virtual machine.')
output linuxJumpboxVMName string = linuxVM.outputs.name
