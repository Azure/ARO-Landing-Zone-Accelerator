# ARO Secure Baseline - Hub (Bicep - AVM)

This Bicep template deploys a hub network using Azure Verified Modules (AVM). The hub is the central point of connectivity to the on-premises network and the internet. The hub includes essential networking components and security features to establish a foundation for your Azure landing zone.

> [!IMPORTANT]
> The purpose of this module is to deploy a sample hub for learning / demo purposes.
> We recommend to bring your own hub and use a template like [ALZ-HUB](https://github.com/Azure/ALZ-Bicep). For more information on `Landing Zone`, please refer to [What is a landing zone?](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/landing-zone/)

## Overview

**Targeted Scope**: Subscription

The template deploys the following resources:

1. Resource Group: Contains all the hub resources.
2. Virtual Network: The hub network with multiple subnets:
    - `Default` subnet with a Network Security Group (NSG).
    - `AzureFirewallSubnet` for the Azure Firewall without NSG.
    - `AzureFirewallManagementSubnet` for the Azure Firewall management without NSG.
    - `AzureBastionSubnet` for Azure Bastion with an NSG: `./nsg/bastion-nsg.jsonc`.
4. Private DNS Zones: For Azure Key Vault and Azure Container Registry.
5. Azure Firewall: Includes a firewall policy and associated public IP addresses for the firewall and its management. The firewall rules are defined in `./firewall/afwp-rule-collection-groups.jsonc`.
6. Azure Bastion: For secure access to virtual machines.
7. Log Analytics Workspace: For centralized logging and monitoring.

### Parameters

The parameters can be set using the cli command `--parameters <parameter-name>=<value>` or in the parameters file `main.bicepparam`. Below you can find a full list of parameters for this template.

<details>
<summary>Table with all parameters</summary>

| Name               | Type   | Description                                                                                                                                                                                                 | Default Value                 |
|--------------------|--------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-------------------------------|
| `workloadName`     | string | The name of the workload. Defaults to hub.                                                                                                                                                                 | `'hub'`                       |
| `location`         | string | The location of the resources. Defaults to the deployment location.                                                                                                                                        | `deployment().location`       |
| `env`              | string | The type of environment. Defaults to DEV.                                                                                                                                                                  | `'DEV'`                       |
| `hash`             | string | The hash to be added to every name like resource, subnet, etc. If not set, a unique string is generated for resources with global name based on its resource group id. The size of the hash is 5 characters. | `null` (optional parameter)   |
| `tags`             | object | The tags to apply to the resources. Defaults to an object with the environment and workload name.                                                                                                          | Object with `environment`, `workload`, and optionally `hash` |
| `enableAvmTelemetry` | bool | Enable Azure Verified Modules (AVM) telemetry. Defaults to true.                                                                                                                                           | `true`                        |
| `resourceGroupName`         | string | The name of the resource group for the hub. Defaults to the naming convention `<abbreviation-resource-group>-<workload>-<lower-case-env>-<location-short>[-<hash>]`.                                                      | `generateResourceName('resourceGroup', workloadName, env, location, null, hash)`  |
| `virtualNetworkName`        | string | The name of the virtual network for the hub. Defaults to the naming convention `<abbreviation-virtual-network>-<workload>-<lower-case-env>-<location-short>[-<hash>]`.                                                     | `generateResourceName('virtualNetwork', workloadName, env, location, null, hash)`|
| `virtualNetworkAddressPrefix` | string | The CIDR for the virtual network. Defaults to `10.0.0.0/16`.                                                                                                                                                              | `'10.0.0.0/16'`                                       |
| `dnsServers`                | string | array | The DNS servers (Optional).                                                                                                                                                                                                  | `null` (optional parameter)                                                    |
| `defaultSubnetAddressPrefix` | string | The default subnet address prefix. Defaults to `10.0.0.0/24`.                                                                                                                                                               | `'10.0.0.0/24'`                                       |
| `defaultSubnetName`         | string | The name of the default subnet. Defaults to `default`.                                                                                                                                                                       | `'default'`                                           |
| `defaultSubnetNetworkSecurityGroupName`     | string | The name of the default subnet network security group. Defaults to the naming convention `<abbreviation-nsg>-<default-subnet-name>[-<hash>]`.                                                                                   | `generateResourceNameFromParentResourceName('networkSecurityGroup', defaultSubnetName, null, hash)`|
| `firewallSubnetAddressPrefix`               | string | The address prefix for the firewall subnet. Defaults to `10.0.1.0/26`.                                                                                                                                                        | `'10.0.1.0/26'`                                                                                     |
| `firewallManagementSubnetAddressPrefix`     | string | The address prefix for the firewall management subnet. Defaults to `10.0.2.0/26`.                                                                                                                                               | `'10.0.2.0/26'`                                                                                     |
| `firewallPublicIpName`                      | string | The name of the public IP for the firewall. Defaults to the naming convention `<abbreviation-public-ip>-<firewall-name>[-<hash>]`.                                                                                            | `generateResourceNameFromParentResourceName('publicIp', firewallName, null, hash)`                  |
| `firewallManagementPublicIpName`            | string | The name of the public IP for the firewall management. Defaults to the naming convention `<abbreviation-public-ip>-<firewall-name>-mgmt[-<hash>]`.                                                                              | `generateResourceNameFromParentResourceName('publicIp', firewallName, 'mgmt', hash)`                |
| `bastionSubnetAddressPrefix`                | string | The address prefix for the bastion subnet. Defaults to `10.0.3.0/27`.                                                                                                                                                          | `'10.0.3.0/27'`                                                                                     |
| `bastionSubnetNetworkSecurityGroupName`     | string | The name of the bastion subnet network security group. Defaults to the naming convention `<abbreviation-nsg>-AzureBastionSubnet[-<hash>]`.                                                                                      | `generateResourceNameFromParentResourceName('networkSecurityGroup', 'AzureBastionSubnet', null, hash)`|
| `bastionPublicIpName`                       | string | The name of the bastion public IP. Defaults to the naming convention `<abbreviation-public-ip>-<bastion-name>[-<hash>]`.                                                                                                      | `generateResourceNameFromParentResourceName('publicIp', bastionName, null, hash)`                   |
| `linkKeyvaultDnsZoneToHubVnet`              | bool | Link the key vault private DNS zone to the hub vnet. Defaults to false. This is required if a DNS resolver is deployed in the hub.                                                                                             | `false`                                                                                             |
| `linkAcrDnsZoneToHubVnet`                   | bool | Link the ACR private DNS zone to the hub vnet. Defaults to false. This is required if a DNS resolver is deployed in the hub.                                                                                                   | `false`                                                                                             |
| `firewallName`              | string | The name of the firewall. Defaults to the naming convention `<abbreviation-firewall>-<workload>-<lower-case-env>-<location-short>[-<hash>]`.                                                   | `generateResourceName('firewall', workloadName, env, location, null, hash)`  |
| `firewallAvailabilityZone`  | array | The availability zones for the firewall. Defaults to an array with all availability zones (1, 2 and 3).                                                                                         | `[ 1, 2, 3 ]`                                                                 |
| `firewallPolicyName`        | string | The name of the firewall policy. Defaults to the naming convention `<abbreviation-firewall-policy>-<workload>-<lower-case-env>-<location-short>[-<hash>]`.                                      | `generateResourceName('firewallPolicy', workloadName, env, location, null, hash)`|
| `firewallPolicyRuleGroupName` | string | The name of the firewall policy rule group. Defaults to the naming convention `<abbreviation-firewall-policy-rule-group>-<workload>-<lower-case-env>-<location-short>[-<hash>]`.            | `generateResourceName('firewallPolicyRuleGroup', workloadName, env, location, null, hash)`|
| `bastionName`               | string | The name of the bastion. Defaults to the naming convention `<abbreviation-bastion>-<workload>-<lower-case-env>-<location-short>[-<hash>]`.                                                     | `generateResourceName('bastion', workloadName, env, location, null, hash)`  |
| `logAnalyticsWorkspaceName` | string | The name of the log analytics workspace. Defaults to the naming convention `<abbreviation-log-analytics>-<workload>-<lower-case-env>-<location-short>[-<hash>]`.                               | `generateResourceName('logAnalyticsWorkspace', workloadName, env, location, null, hash)`|
</details>

### Outputs

These are the output of the deployment:

| Output Name                    | Type    | Description                                         |
|--------------------------------|---------|-----------------------------------------------------|
| `Hub Virtual Network ID`       | string  | The resource ID of the Hub Virtual Network.         |
| `Log Analytics Workspace ID`   | string  | The resource ID of the Log Analytics Workspace.     |
| `Key Vault Private DNS Zone ID`| string  | The resource ID of the Key Vault Private DNS Zone.  |
| `ACR Private DNS Zone ID`      | string  | The resource ID of the ACR Private DNS Zone.        |
| `Firewall Private IP`          | string  | The private IP address of the firewall.             |

These outputs will be used in subsequent deployments to link resources to the hub network.

## Deployment

To deploy this hub, follow these steps:
1. Review the Bicep template and ensure it meets your requirements.
1. Review the parameters and adjust them in `main.bicepparam` as needed.
1. Navigate to the directory containing the Bicep file.

    ```bash
    cd ARO-Landing-Zone-Accelerator/Scenarios/Secure-Baseline/bicepWithAVM/01-Hub/
    ```

1. Deploy the template:

    ```bash
    az deployment sub create --name <deployment-name> --location <region> --template-file main.bicep --parameters main.bicepparam
    ```

    Replace `<deployment-name>` with a name for the deployment and `<region>` with the Azure region where you want to deploy the resources.

## Next Step

After deploying the hub, you can deploy the spoke network using the Bicep template in `02-Spoke/`.

:arrow_forward: [Spoke](../02-Spoke/README.md)
