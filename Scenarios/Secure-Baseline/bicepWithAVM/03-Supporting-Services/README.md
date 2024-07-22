# ARO Secure Baseline - Supporting Services (Bicep - AVM)

This Bicep template deploys the supporting services for the ARO cluster.

## Overview

**Targeted Scope**: Resource Group (e.g. Spoke Resource Group)

This template deploys the following resources:

1. Azure Key Vault: use for the Disk Encryption Set (DES). If you hav a shared Key Vault, you can update the script to use this one instead. The Key Vault for the application should be a separate one to ensure that the application have no access to encryption keys by design. By default the key vault is a `premium` sku and enable purge protection for 90 days as purge protection is required for DES.
1. A private endpoint for the Key Vault in the private endpoints subnet of the spoke VNET. A record is added to the private DNS zone for the Key Vault.
1. Disk Encryption Set (DES): use for the ARO cluster. The DES is used to encrypt the disks / encryption at host for the ARO cluster with Customer Managed Key (CMK). There is an option to use Platform Managed Key (PMK) as well and therefore to do not deploy the DES. DES can be set only at cluster creation time and cannot be changed after the cluster is created. This is why it is important to consider this asperct before deploying the ARO cluster.
1. A key generated in the Key Vault for the DES. This key is generated only if DES is deployed.
1. User Assigned Managed Identity: use for the Disk Encryption Set (DES) with `Key Vault Crypto User` role on the scope of the key generated for the DES.
1. Azure Container Registry: use for the ARO cluster. This will be setup in OpenShift portal during the deployment of the workloads.
1. A private endpoint for the Azure Container Registry in the private endpoints subnet of the spoke VNET. A record is added to the private DNS zone for the Azure Container Registry.
1. 2 Jumpbox VMs (Optional):
    1. A Windows Jumpbox: used to access the ARO cluster portal.
    1. A Linux Jumpbox: used for OCI (OpenShift CLI) access to the ARO cluster.

### Parameters

he parameters can be set using the cli command `--parameters <parameter-name>=<value>` or in the parameters file `main.bicepparam`. Below you can find a table with all parameters with. The required parameters are:

- `privateEndpointSubnetResourceId`: the resource id of the subnet used for the private endpoints that will be created.
- `jumpBoxSubnetResourceId`: the resource id of the subnet used for the jumpbox VMs that will be created.
- `keyVaultPrivateDnsZoneResourceId`: the resource id of the private DNS zone used for the Key Vault.
- `acrPrivateDnsZoneResourceId`: the resource id of the private DNS zone used for the Azure Container Registry.
- `logAnalyticsWorkspaceResourceId`: the resource id of the Log Analytics Workspace used for the jumpbox VMs.

> [!TIP]
> These required parameters can be get from the outputs of the hub and the spoke deployments using the following commands:
>
> ```bash
> <variable-name>=$(az deployment sub show --name <hub-deployment-name> --query properties.outputs.<output-name>.value -o tsv)
> ```

The following parameters are required only if you want to deploy the jumpbox VMs:

- `windowsAdminPassword`: the password for the Windows Jumpbox.
- `linuxAdminPassword`: the password for the Linux Jumpbox.

> [!TIP]
> In `bicepparam` file you can set the parameters in the following ways:
> - Using `getSecret` function to access the secret from the key vault.
> - Using `readEnvironmentVariable ` function to access the environment variable.

<details>
<summary>Table with all parameters</summary>

| Name               | Type   | Description                                                                                                                                                                                                 | Default Value                 |
|--------------------|--------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-------------------------------|
| `workloadName`     | string | The name of the workload. Defaults to aro-lza.                                                                                                                                                                 | `aro-lza`                       |
| `location`         | string | The location of the resources. Defaults to the deployment location.                                                                                                                                        | `deployment().location`       |
| `env`              | string | The type of environment. Defaults to DEV.                                                                                                                                                                  | `DEV`                       |
| `hash`             | string | The hash to be added to every name like resource, subnet, etc. If not set, a unique string is generated for resources with global name based on its resource group id. The size of the hash is 5 characters. | `null` (optional parameter)   |
| `tags`             | object | The tags to apply to the resources. Defaults to an object with the environment and workload name.                                                                                                          | Object with `environment`, `workload`, and optionally `hash` |
| `enableAvmTelemetry` | bool | Enable Azure Verified Modules (AVM) telemetry. Defaults to true.                                                                                                                                           | `true`                        |
| `privateEndpointSubnetResourceId` | string | The resource id of the subnet where the private endpoint will be created. | |
| `jumpBoxSubnetResourceId`        | string | The resource id of the subnet where the jump box will be created.    | |
| `keyVaultPrivateDnsZoneResourceId` | string | The resource id of the private DNS zone for the key vault.          | |
| `acrPrivateDnsZoneResourceId`    | string | The resource id of the private DNS zone for the container registry.  | |
| `keyVaultName`                    | string          | The name of the key vault. Defaults to the naming convention `<abbreviation-key-vault><workloadName><lower-case-env><location-short>[<hash>]`.                                                                                | `generateUniqueGlobalName('keyVault', workloadName, env, location, null, hash, [resourceGroup().id], 5, 24, false)`|
| `keyVaultSku`                     | keyVaultSkuType | The SKU of the key vault. Defaults to premium.                                                                                                                                                                                 | `'premium'`                                                                                         |
| `enablePurgeProtection`           | bool            | Enable purge protection. Defaults to true. If disk encryption set is enabled, it is set to true as it is required by the cluster.                                                                                              | `true || deployDiskEncryptionSet`                                                                   |
| `softDeleteRetentionInDays`       | int             | The number of days to retain soft deleted keys. Defaults to 90.                                                                                                                                                               | `90`                                                                                                |
| `enableVaultForDeployment`        | bool            | Property to specify whether Azure Virtual Machines are permitted to retrieve certificates stored as secrets from the key vault. Defaults to false.                                                                             | `false`                                                                                             |
| `enableVaultForTemplateDeployment` | bool            | Property to specify whether Azure Resource Manager is permitted to retrieve secrets from the key vault. Defaults to false.                                                                                                     | `false`                                                                                             |
| `enableVaultForDiskEncryption`    | bool            | Property to specify whether Azure Disk Encryption is permitted to retrieve secrets from the key vault. Defaults to true.                                                                                                        | `true`                                                                                              |
| `keys`                            | keyType[]       | The key to be created in the key vault. Defaults to an empty array. If deployDiskEncryptionSet is set to true, a key for disk encryption set will be created.                                                                  | `[]`                                                                                                |
| `secrets`                         | array           |                                                                                                                                                                                                                               |                                                                                                     |
| `keyVaultPrivateEndpointName`     | string          | The name of the private endpoint for the key vault. Defaults to the naming convention `<abbreviation-private-endpoint>-<key-vault-name>`.                                                                                      | `generateResourceNameFromParentResourceName('privateEndpoint', keyVaultName, null, hash)`           |
| `deployDiskEncryptionSet`                        | bool       | Flag to determine if the disk encryption set should be deployed. Defaults to false.                                                                                                                                           | `true`                                                                                              |
| `diskEncryptionSetName`                          | string     | The name of the disk encryption set. Defaults to the naming convention `<abbreviation-disk-encryption-set>-<workloadName>-<lower-case-env>-<location-short>[-<hash>]`.                                                     | `generateResourceName('diskEncryptionSet', workloadName, env, location, null, hash)`                |
| `userManagedIdentityToAccessDiskEncryptionSetKeyName` | string | The name of the user managed identity to access the key vault for the disk encryption set. Defaults to the naming convention `<abbreviation-user-managed-identity>-<disk-encryption-set-name>[-<hash>]`.              | `generateResourceNameFromParentResourceName('userManagedIdentity', diskEncryptionSetName, null, hash)`|
| `diskEncryptionSetEncryptionType`               | string     | The type of encryption to be used for the disk encryption set. Defaults to `EncryptionAtRestWithCustomerKey`. Currently `ConfidentialVmEncryptedWithCustomerKey` is not supported by the AVM template.                     | `'EncryptionAtRestWithCustomerKey'`                                                                |
| `diskEncryptionSetKey`                           | keyType    | The key to be created in the key vault for the disk encryption set. Defaults to an empty array.                                                                                                                             | `{ name: generateResourceNameFromParentResourceName('keyVaultKey', diskEncryptionSetName, null, hash), kty: 'RSA', keySize: 2048, rotationPolicy: { attributes: { expiryTime: 'P2Y' }, lifetimeActions: [ { action: { type: 'Rotate' }, trigger: { timeBeforeExpiry: 'P2M' } }, { action: { type: 'Notify' }, trigger: { timeBeforeExpiry: 'P30D' } } ] } }` |
| `containerRegistryName`                   | string                  | The name of the container registry. Defaults to the naming convention `<abbreviation-container-registry>-<workloadName>-<lower-case-env>-<location-short>[-<hash>]`.                                                      | `generateUniqueGlobalName('containerRegistry', workloadName, env, location, null, hash, [resourceGroup().id], 5, 50, false)`|
| `containerRegistrySku`                    | containerRegistrySkuType | The SKU of the container registry. Defaults to Premium.                                                                                                                                                                        | `'Premium'`                                                                                         |
| `containerRegistryPrivateEndpointName`    | string                  | The name of the private endpoint for the container registry. Defaults to the naming convention `<abbreviation-private-endpoint>-<container-registry-name>`.                                                                | `generateResourceNameFromParentResourceName('privateEndpoint', containerRegistryName, null, hash)`  |
| `deployWindowsJumpbox`      | bool                  | Flag to determine if the Windows VM should be deployed. Defaults to true.                                                                                                                                                     | `true`                                                                                              |
| `windowsVMName`             | string                | The name of the Windows virtual machine. Defaults to the naming convention `<abbreviation-virtual-machine><workloadName>-<lower-case-env>-<location-short>-win-jbx[-<hash>]`.                                                  | `generateResourceName('virtualMachine', workloadName, env, location, 'win-jbx', hash)`              |
| `windowsVMComputerName`     | string                | The name of the Windows virtual machine computer. Defaults to the naming convention `<take(workloadName, 7)>-win-jbx`.                                                                                                         | `'${take(workloadName, 7)}-win-jbx'`                                                               |
| `imageReferenceWindows`     | imageReferenceType    | The image reference for the Windows VM.                                                                                                                                                                                        | `{ offer: 'WindowsServer', publisher: 'MicrosoftWindowsServer', sku: '2022-datacenter-azure-edition', version: 'latest' }` |
| `windowsVMSize`             | string                | The size of the Windows virtual machine. Defaults to Standard_B2ms.                                                                                                                                                            | `'Standard_B2ms'`                                                                                  |
| `windowsAdminUsername`      | string                | The username of the local administrator account for the Windows virtual machine. Defaults to arolzauser.                                                                                                                        | `'arolzauser'`                                                                                     |
| `windowsAdminPassword`      | string                | The password for the local administrator account for the Windows virtual machine.                                                                                                                                              |                                                                                                     |
| `windowsNicConfigurations`  | nicConfigurationType[] | The NIC configurations for the Windows virtual machine. Defaults to a single NIC configuration with the name `ipconfig01` and the subnet resource id of the jump box subnet.                                                   | `[ { deleteOptions: 'Delete', ipConfigurations: [ { name: 'ipconfig01', subnetResourceId: jumpBoxSubnetResourceId } ], nicSuffix: '-nic-01', enableAcceleratedNetworking: false } ]` |
| `windowsOsDiskConfiguration` | osDiskType           | The OS disk configuration for the Windows virtual machine. Defaults to a managed disk with a storage account type of Standard_LRS.                                                                                             | `{ createOption: 'FromImage', deleteOption: 'Delete', managedDisk: { storageAccountType: 'Standard_LRS' }, diskSizeGB: 128 }` |
| `deployLinuxJumpbox`          | bool                  | Flag to determine if the Linux VM should be deployed. Defaults to true.                                                                                                                                                       | `true`                                                                                              |
| `linuxVMName`                 | string                | The name of the Linux virtual machine. Defaults to the naming convention `<abbreviation-virtual-machine><workloadName>-<lower-case-env>-<location-short>-lnx-jbx[-<hash>]`.                                                    | `generateResourceName('virtualMachine', workloadName, env, location, 'lnx-jbx', hash)`              |
| `linuxVMComputerName`         | string                | The name of the Linux virtual machine computer. Defaults to the naming convention `<take(workloadName, 7)>-lnx-jbx`.                                                                                                           | `'${take(workloadName, 7)}-lnx-jbx'`                                                               |
| `imageReferenceLinux`         | imageReferenceType    | The image reference for the Linux VM.                                                                                                                                                                                        | `{ offer: '0001-com-ubuntu-server-jammy', publisher: 'Canonical', sku: '22_04-lts-gen2', version: 'latest' }` |
| `linuxVMSize`                 | string                | The size of the Linux virtual machine. Defaults to Standard_B2ms.                                                                                                                                                            | `'Standard_B2ms'`                                                                                  |
| `linuxAdminUsername`          | string                | The username of the local administrator account for the Linux virtual machine. Defaults to arolzauser.                                                                                                                        | `'arolzauser'`                                                                                     |
| `linuxAdminPassword`          | string                | The password for the local administrator account for the Linux virtual machine.                                                                                                                                              |                                                                                                     |
| `linuxNicConfigurations`      | nicConfigurationType[] | The NIC configurations for the Linux virtual machine. Defaults to a single NIC configuration with the name `ipconfig01` and the subnet resource id of the jump box subnet.                                                   | `[ { deleteOptions: 'Delete', ipConfigurations: [ { name: 'ipconfig01', subnetResourceId: jumpBoxSubnetResourceId } ], nicSuffix: '-nic-01', enableAcceleratedNetworking: false } ]` |
| `linuxOsDiskConfiguration`    | osDiskType           | The OS disk configuration for the Linux virtual machine. Defaults to a managed disk with a storage account type of Standard_LRS.                                                                                             | `{ createOption: 'FromImage', deleteOption: 'Delete', managedDisk: { storageAccountType: 'Standard_LRS' }, diskSizeGB: 128 }` |
| `logAnalyticsWorkspaceResourceId` | string            | The Log Analytics workspace resource id. This is required to enable monitoring.                                                                                                                                              |                                                                                                     |
</details>

### Outputs

These are the outputs of the template:

\| Output                        \| Type    \| Description                                                                                   \|
\|-------------------------------\|---------\|-----------------------------------------------------------------------------------------------\|
\| `diskEncryptionSetResourceId`  \| string  \| The resource id of the key vault. If `deployDiskEncryptionSet` is true, it returns the disk encryption set's resource id; otherwise, it returns an empty string. \|

These outputs will be used in subsequent deployments.

## Deployment

To deploy the supporting services, follow the steps:

1. Navigate to the directory containing the Bicep file.

    ```bash
    cd ../03-Supporting-Services
    ```

1. Deploy the template:

    ```bash
    az deployment group create \
        --name <deployment-name> \
        --resource-group <spoke-resource-group> \
        --template-file main.bicep \
        --parameters ./main.bicepparam
    ```

    Replace `<deployment-name>` with the name of the deployment and `<spoke-resource-group>` with the name of the spoke resource group.

## Next Step

After deploying the supporting services, you can deploy the ARO cluster.

:arrow_forward: [ARO cluster](../04-ARO-Cluster/README.md)
