# ARO Secure Baseline - Spoke (Bicep - AVM)

The purpose of this module is to deploy the spoke resource group and the spoke virtual network for an Azure Red Hat OpenShift (ARO) secure baseline environment.

## Overview

This template deploys a comprehensive set of resources to establish a secure spoke network for an ARO cluster. The deployment includes:

- Resource Group: A container for all the spoke resources
- Virtual Network: The main network infrastructure for the ARO cluster
- Subnets: 
  - Master Nodes Subnet: For ARO master nodes
  - Worker Nodes Subnet: For ARO worker nodes
  - Private Endpoints Subnet: For private endpoint connections
  - Jumpbox Subnet: For secure access to the cluster
- Network Security Groups: To secure network traffic
- Route Table: For custom routing of network traffic
- Peering: To connect the spoke network with the hub network

## Architecture

The spoke network is designed to work in conjunction with a hub network in a hub-and-spoke architecture. This design provides enhanced security, centralized management, and efficient resource utilization.

![alt text](hub-spoke.png)

## Features

- Secure network design with separate subnets for different purposes
- Network Security Groups to control inbound and outbound traffic
- Custom routing capabilities with Route Table
- Integration with hub network through peering
- Prepared subnets for ARO cluster deployment
- Jumpbox subnet for secure administrative access
- Private Endpoints subnet for secure Azure service connections
- Extensible design with optional additional subnets

## Prerequisites

Before deploying this spoke network, ensure you have:

1. Azure CLI (latest version) installed on your local machine
2. Access to an Azure subscription with sufficient permissions
3. A deployed hub network with its:
   - Virtual Network Resource Id
   - Log Analytics Workspace Resource Id

## Deployment

To deploy this hub, follow these steps:

1. Ensure you have the latest version of Azure CLI installed.
2. Clone this repository to your local machine.
```bash
    git clone https://github.com/Azure/ARO-Landing-Zone-Accelerator
```
3. Navigate to the directory containing the Bicep file.
```bash
    cd ARO-Landing-Zone-Accelerator/Scenarios/Secure-Baseline/bicepWithAVM/02-Spoke/
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
    az deployment sub create 
            --location <region> 
            --template-file main.bicep 
            --parameters hash=<hash> hubVirtualNetworkId=<hubVirtualNetworkId> logAnalyticsWorkspaceId=<logAnalyticsResourceId>
```
Replace `<region>`, `<hash>`, `<hubVirtualNetworkId>`, and `<logAnalyticsResourceId>` with appropriate values. The `<hash>` value you provide must be a key consisting of 3 to 5 characters.

## Parameters

The following parameters can be set in the main.bicep file:

### Required Parameters

| Parameter | Description | Default Value |
|-----------|-------------|---------------|
| hubVirtualNetworkResourceId | The resource id of the hub virtual network | - (Required) |
| logAnalyticsResourceId | The Log Analytics Resource id | - (Required) |

### Optional Parameters

| Parameter | Description | Default Value |
|-----------|-------------|---------------|
| workloadName | The name of the workload | 'aro-lza' |
| location | The location of the resources | Deployment location |
| env | The type of environment (DEV/TST/UAT/PRD) | 'DEV' |
| hash | A hash to be added to resource names (optional) | null |
| tags | The tags to apply to the resources | Environment and workload name |
| enableAvmTelemetry | Enable Azure Verified Modules telemetry | true |
| resourceGroupName | The name of the resource group | Based on naming convention |
| virtualNetworkName | The name of the spoke virtual network | Based on naming convention |
| virtualNetworkAddressPrefix | The CIDR for the spoke virtual network | '10.1.0.0/16' |
| dnsServers | The DNS server array (optional) | null |
| masterNodesSubnetName | The name of the master nodes subnet | Based on naming convention |
| masterNodesSubnetAddressPrefix | The CIDR for the master nodes subnet | '10.1.0.0/23' |
| workerNodesSubnetName | The name of the worker nodes subnet | Based on naming convention |
| workerNodesSubnetAddressPrefix | The CIDR for the worker nodes subnet | '10.1.2.0/23' |
| privateEndpointsSubnetName | The name of the private endpoints subnet | Based on naming convention |
| privateEndpointsSubnetAddressPrefix | The CIDR for the private endpoints subnet | '10.1.4.0/24' |
| privateEndpointsNetworkSecurityGroupName | The name of the NSG for private endpoints subnet | Based on naming convention |
| jumpboxSubnetName | The name of the jumpbox subnet | Based on naming convention |
| jumpboxSubnetAddressPrefix | The CIDR for the jumpbox subnet | '10.1.5.0/24' |
| jumpboxNetworkSecurityGroupName | The name of the NSG for jumpbox subnet | Based on naming convention |
| otherSubnets | The configuration for other subnets (optional) | null |
| aroRouteTableName | The name of the route table for ARO subnets | Based on naming convention |
| firewallPrivateIpAddress | The private IP address of the firewall (optional) | null |

Note: Many parameter default values are based on a naming convention using the `getResourceName()` or `getResourceNameFromParentResourceName()` functions.

## Post-Deployment

After successful deployment:

1. Verify all resources are created in the Azure portal.
2. Check the peering status between the hub and spoke networks.
3. Validate the Network Security Group rules.
4. Ensure the Route Table is correctly associated with the required subnets.

## Customization

This template is designed to be flexible. You can customize it by:

- Adding additional subnets using the `otherSubnets` parameter.
- Modifying Network Security Group rules in the `nsg/` folder.
- Adjusting IP address ranges to fit your network architecture.
