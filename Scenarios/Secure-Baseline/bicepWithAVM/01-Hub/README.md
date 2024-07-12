# ARO Secure Baseline - Bicep with Azure Verified Modules (AVM)

> [!IMPORTANT]
> The purpose of this module is to deploy a sample hub for learning / demo purposes.
> We recommend to bring your own hub and use a template like [ALZ-HUB](https://github.com/Azure/ALZ-Bicep). For more information on `Landing Zone`, please refer to [What is a landing zone?](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/landing-zone/)

## Overview

This Bicep template deploys a hub network using Azure Verified Modules (AVM). The hub includes essential networking components and security features to establish a foundation for your Azure landing zone.

## Resources Deployed

The template deploys the following resources:

1. Resource Group: Contains all the hub resources.
2. Virtual Network: The main hub network with multiple subnets.
3. Network Security Groups: For default and Azure Bastion subnets.
4. Private DNS Zones: For Azure Key Vault and Azure Container Registry.
5. Azure Firewall: Includes a firewall policy and associated public IP addresses.
6. Azure Bastion: For secure access to virtual machines.
7. Log Analytics Workspace: For centralized logging and monitoring.

## Deployment

To deploy this hub, follow these steps:

1. Ensure you have the latest version of Azure CLI installed.
2. Clone this repository to your local machine.
```bash
    git clone https://github.com/Azure/ARO-Landing-Zone-Accelerator
```
3. Navigate to the directory containing the Bicep file.
```bash
    cd ARO-Landing-Zone-Accelerator/Scenarios/Secure-Baseline/bicepWithAVM/01-Hub/
```
4. Log in to your Azure account:
```bash
    az login
```
5. Set your subscription:
```bash
    az account set --subscription <Your-Subscription-Id>
```
6. Deploy the template:
```bash
    az deployment sub create --location <region> --template-file main.bicep --parameters hash=<hash>
```
Replace `<region>`, and `<hash>` with appropriate values. The `<hash>` value you provide must be a key consisting of 3 to 5 characters.

## Parameters

The following parameters can be set in the main.bicep file:

| Parameter | Description | Default Value |
|-----------|-------------|---------------|
| workloadName | The name of the workload | 'hub' |
| location | The location of the resources | Deployment location |
| env | The type of environment (DEV/TST/UAT/PRD) | 'DEV' |
| hash | A hash to be added to resource names (optional) | null |
| tags | The tags to apply to the resources | Environment and workload name |
| enableAvmTelemetry | Enable Azure Verified Modules telemetry | true |
| resourceGroupName | The name of the resource group | Based on naming convention |
| virtualNetworkName | The name of the virtual network | Based on naming convention |
| virtualNetworkAddressPrefix | The CIDR for the virtual network | '10.0.0.0/16' |
| dnsServers | The DNS servers (optional) | null |
| defaultSubnetAddressPrefix | The default subnet address prefix | '10.0.0.0/24' |
| defaultSubnetName | The name of the default subnet | 'default' |
| defaultSubnetNetworkSecurityGroupName | The name of the default subnet NSG | Based on naming convention |
| firewallSubnetAddressPrefix | The address prefix for the firewall subnet | '10.0.1.0/26' |
| firewallManagementSubnetAddressPrefix | The address prefix for the firewall management subnet | '10.0.2.0/26' |
| firewallPublicIpName | The name of the public IP for the firewall | Based on naming convention |
| firewallManagementPublicIpName | The name of the public IP for firewall management | Based on naming convention |
| bastionSubnetAddressPrefix | The address prefix for the bastion subnet | '10.0.3.0/27' |
| bastionSubnetNetworkSecurityGroupName | The name of the bastion subnet NSG | Based on naming convention |
| bastionPublicIpName | The name of the bastion public IP | Based on naming convention |
| linkKeyvaultDnsZoneToHubVnet | Link key vault private DNS zone to hub vnet | false |
| linkAcrDnsZoneToHubVnet | Link ACR private DNS zone to hub vnet | false |
| firewallName | The name of the firewall | Based on naming convention |
| firewallAvailabilityZone | The availability zones for the firewall | [1, 2, 3] |
| firewallPolicyName | The name of the firewall policy | Based on naming convention |
| firewallPolicyRuleGroupName | The name of the firewall policy rule group | Based on naming convention |
| bastionName | The name of the bastion | Based on naming convention |
| logAnalyticsWorkspaceName | The name of the log analytics workspace | Based on naming convention |

Note: Many parameter default values are based on a naming convention using the `getResourceName()` or `getResourceNameFromParentResourceName()` functions.

Refer to the Bicep file for a complete list of parameters and their descriptions.

## Networking Configuration

The hub network is configured with the following subnets:

- Default subnet
- AzureFirewallSubnet
- AzureFirewallManagementSubnet
- AzureBastionSubnet

Each subnet is configured with appropriate network security groups and address prefixes.

## Firewall Policy

The Azure Firewall is deployed with a basic policy. You can customize the firewall rules by modifying the `firewall/afwp-rule-collection-groups.jsonc` file.

## Monitoring

A Log Analytics workspace is deployed for centralized logging. Diagnostic settings are configured to send logs from various resources to this workspace.

## Outputs

The template provides several useful outputs:

- Hub Virtual Network ID
- Log Analytics Workspace ID
- Key Vault Private DNS Zone ID
- ACR Private DNS Zone ID
- Firewall Private IP

These outputs can be used in subsequent deployments or for reference.

## Customization

You can customize this template by modifying the Bicep file. Common customizations include:

- Adjusting network address spaces
- Adding or removing subnets
- Modifying firewall rules
- Adding additional resources to the hub

Ensure to test your changes thoroughly before deploying to production environments.

## Notes

- This template uses Azure Verified Modules (AVM) for resource deployment, ensuring best practices and consistent resource configuration.
- The deployment uses a subscription-level scope, allowing for flexible resource group naming and placement.
- Review and adjust the tags applied to resources as needed for your organization's tagging strategy.

For more detailed information on each resource and its configuration, please refer to the comments within the Bicep file.