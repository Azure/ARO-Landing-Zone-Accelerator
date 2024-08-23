# ARO Secure Baseline - Spoke (Bicep - AVM)

This Bicep template deploys the foundation for the spoke in which the Azure Red Hat OpenShift (ARO) cluster will be deployed. The spoke network is designed to work in conjunction with a hub network in a hub-and-spoke network topology. A second template is provided to link the Private DNS Zones to spoke network.

## Overview

**Targeted Scope**: Subscription

The template deploys the following resources:

1. Resource Group: Contains all the spoke resources.
2. Virtual Network: The spoke virtual network with multiple subnets:
     - Master Node Subnet: used to deploy the master nodes of the ARO cluster. It cannot present a Network Security Group (NSG) as it is not yet supported by ARO.
    - Worker Node Subnet: used to deploy the worker nodes of the ARO cluster. It cannot present a Network Security Group (NSG) as it is not yet supported by ARO.
    - Private Endpoints Subnet: used to deploy the private endpoints for all supporting services like the Azure Container Registry and the Azure Key Vault.
    - Jumpbox Subnet: used to deploy the jumpbox virtual machines that are used to access the control plane of the ARO cluster.
    - Other Subnets: Optional additional subnets.
3. Network Peering: Peering connection between the hub and spoke networks (2-way peering).
4. Route Table: Custom route table used to control the routing of egrees traffic from ARO subnets to the Azure Firewall. This is a key component of User Defined Routing (UDR) in ARO.

> [!NOTE]
> To deploy UDR, you must provide the private IP address of the Azure Firewall in the `firewallPrivateIpAddress` parameter. If you do not provide this value, the route table will not be created and not associated with the worker nodes and master nodes subnets.

### Parameters

The parameters can be set using the cli command `--parameters <parameter-name>=<value>` or in the parameters file `main.bicepparam`. Below you can find a table with all parameters with. The required parameters are:

- `hubVirtualNetworkResourceId`: The resource id of the hub virtual network. This is required for the peering of the spoke network with the hub network.
- `logAnalyticsResourceId`: The Log Analytics Resource id. This is required for diagnostics and monitoring.

> [!TIP]
> These required parameters can be get from the outputs of the hub deployment using the following commands:
>
> ```bash
> <variable-name>=$(az deployment sub show --name <hub-deployment-name> --query properties.outputs.<output-name>.value -o tsv)
> ```

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
| `resourceGroupName`           | string  | The name of the resource group for the spoke. Defaults to the naming convention `<abbreviation-resource-group>-<workload>-<lower-case-env>-<location-short>[-<hash>]`.                                                           | `generateResourceName('resourceGroup', workloadName, env, location, null, hash)`                   |
| `hubVirtualNetworkResourceId` | string  | The resource id of the hub virtual network. This is required to peer the spoke virtual network with the hub virtual network.                                                                                                         |                                                                                                     |
| `virtualNetworkName`          | string  | The name of the spoke virtual network. Defaults to the naming convention `<abbreviation-virtual-network>-<workload>-<lower-case-env>-<location-short>[-<hash>]`.                                                                   | `generateResourceName('virtualNetwork', workloadName, env, location, null, hash)`                  |
| `virtualNetworkAddressPrefix` | string  | The CIDR for the spoke virtual network. Defaults to 10.1.0.0/16.                                                                                                                                                                      | `'10.1.0.0/16'`                                                                                      |
| `dnsServers`                  | array?  | The DNS server array (Optional).                                                                                                                                                                                                  |    `null` (optional parameter)                                                                   |
| `masterNodesSubnetName`           | string  | The name of the master nodes subnet. Defaults to the naming convention `<abbreviation-subnet>-aro-master-<workloadName>-<lower-case-env>-<location-short>[-<hash>]`.                                                           | `generateResourceName('subnet', 'aro-master-${workloadName}', env, location, null, hash)`          |
| `masterNodesSubnetAddressPrefix`  | string  | The CIDR for the master nodes subnet. Defaults to 10.1.0.0/23.                                                                                                                                                                   | `'10.1.0.0/23'`                                                                                     |
| `workerNodesSubnetName`           | string  | The name of the worker nodes subnet. Defaults to the naming convention `<abbreviation-subnet>-aro-worker-<workloadName>-<lower-case-env>-<location-short>[-<hash>]`.                                                           | `generateResourceName('subnet', 'aro-worker-${workloadName}', env, location, null, hash)`          |
| `workerNodesSubnetAddressPrefix`  | string  | The CIDR for the worker nodes subnet. Defaults to 10.1.2.0/23.                                                                                                                                                                   | `'10.1.2.0/23'`                                                                                     |
| `privateEndpointsSubnetName`                 | string  | The name of the private endpoints subnet. Defaults to the naming convention `<abbreviation-subnet>-pep-<workloadName>-<lower-case-env>-<location-short>[-<hash>]`.                                                          | `generateResourceName('subnet', 'pep-${workloadName}', env, location, null, hash)`                 |
| `privateEndpointsSubnetAddressPrefix`        | string  | The CIDR for the private endpoints subnet. Defaults to 10.1.4.0/24.                                                                                                                                                          | `'10.1.4.0/24'`                                                                                     |
| `privateEndpointsNetworkSecurityGroupName`   | string  | The name of the network security group for the private endpoints subnet. Defaults to the naming convention `<abbreviation-nsg>-<privateEndpointsSubnetName>`.                                                               | `generateResourceNameFromParentResourceName('networkSecurityGroup', privateEndpointsSubnetName, null, hash)`|
| `jumpboxSubnetName`                          | string  | The name of the jumpbox subnet. Defaults to the naming convention `<abbreviation-subnet>-jumpbox-<workloadName>-<lower-case-env>-<location-short>[-<hash>]`.                                                                | `generateResourceName('subnet', 'jumpbox-${workloadName}', env, location, null, hash)`             |
| `jumpboxSubnetAddressPrefix`                 | string  | The CIDR for the jumpbox subnet. Defaults to 10.1.5.0/24.                                                                                                                                                                    | `'10.1.5.0/24'`                                                                                     |
| `jumpboxNetworkSecurityGroupName`            | string  | The name of the network security group for the jumpbox subnet. Defaults to the naming convention `<abbreviation-nsg>-<jumpboxSubnetName>`.                                                                                  | `generateResourceNameFromParentResourceName('networkSecurityGroup', jumpboxSubnetName, null, hash)`|
| `otherSubnets`                    | subnetType[]? | The configuration for other subnets (Optional).                                                                                                                                                                                |   `null` (optional parameter)                                                                       |
| `aroRouteTableName`               | string     | The name of the route table for the two ARO subnets. Defaults to the naming convention `<abbreviation-route-table>-aro-<lower-case-env>-<location-short>[-<hash>]`.                                                            | `generateResourceName('routeTable', 'aro', env, location, null, hash)`                             |
| `firewallPrivateIpAddress`        | string?    | The private IP address of the firewall to route ARO egress traffic to it (Optional). If not provided, the route table will not be created and not associated with the worker nodes and master nodes subnets.                    |  `null` (optional parameter)                                 |
| `logAnalyticsWorkspaceResourceId` | string     | The Log Analytics workspace resource id. This is required to enable monitoring.                                                                                                                                                 |                                                                                                     |
</details>

### Outputs

These are the outputs of the deployment:

| Output Name                          | Type   | Description                                                  |
|--------------------------------------|--------|--------------------------------------------------------------|
| `resourceGroupName`                  | string | The name of the spoke resource group.                              |
| `virtualNetworkResourceId`           | string | The resource id of the spoke virtual network.                      |
| `masterNodesSubnetResourceId`        | string | The resource id of the master nodes subnet.                  |
| `workerNodesSubnetResourceId`        | string | The resource id of the worker nodes subnet.                  |
| `privateEndpointsSubnetResourceId`   | string | The resource id of the private endpoints subnet.             |
| `jumpboxSubnetResourceId`            | string | The resource id of the jumpbox subnet.                       |
| `routeTableResourceId`               | string | The resource id of the private endpoints network security group. Empty if the route table is not deployed. |

These outputs will be used in subsequent deployments.

## Deployment

To deploy this spoke, follow these steps:

1. Navigate to the directory containing the Bicep file.

    ```bash
        cd ../02-Spoke/
    ```

1. Deploy the template:

    ```bash
    az deployment sub create --name <deployment-name> --location <region> --template-file main.bicep --parameters main.bicepparam
    ```

    Replace `<deployment-name>` with a name for the deployment and `<region>` with the Azure region where you want to deploy the resources.


## Link Private DNS Zones to Spoke Network

There is a second Bicep template used to link each of the Private DNS Zones to the spoke network `link-private-dns-to-network.bicep`. The template link 1 network to 1 Private DNS Zone.

**Targeted Scope**: Resource Group in which the Private DNS Zone is deployed

### Parameters

The parameters can be set using the cli command `--parameters <parameter-name>=<value>` or in the parameters file `main.bicepparam`. Below you can find a table with all parameters with. The required parameters are:

- `privateDnsZoneName`: The name of the Private DNS Zone in the scope of the resource group.
- `virtualNetworkResourceId`: The resource id of the virtual network to link the Private DNS Zone to.

> [!TIP]
> These required parameters can be get from the outputs of the hub and the spoke deployments using the following commands:
>
> ```bash
> <variable-name>=$(az deployment sub show --name <hub-deployment-name> --query properties.outputs.<output-name>.value -o tsv)
> ```

<details>
<summary>Table with all parameters</summary>

| Name               | Type   | Description                                                                                                                                                                                                 | Default Value                 |
|--------------------|--------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-------------------------------|
| `workloadName`     | string | The name of the workload. Defaults to aro-lza.                                                                                                                                                                 | `aro-lza`                       |
| `location`         | string | The location of the resources. Defaults to the deployment location.                                                                                                                                        | `deployment().location`       |
| `env`              | string | The type of environment. Defaults to DEV.                                                                                                                                                                  | `DEV`                       |
| `hash`             | string | The hash to be added to every name like resource, subnet, etc. If not set, a unique string is generated for resources with global name based on its resource group id. The size of the hash is 5 characters. | `null` (optional parameter)   |
| `tags`             | object | The tags to apply to the resources. Defaults to an object with the environment and workload name.                                                                                                          | Object with `environment`, `workload`, and optionally `hash` |
| `virtualNetworkLinkName`  | string  | The name of the virtual network link. Defaults to the naming convention `<abbreviation-virtual-network-link>-<virtual-network-name>[-<hash>]`.  | `generateResourceNameFromParentResourceName('virtualNetworkLink', last(split(virtualNetworkResourceId, '/')), null, hash)`|
| `privateDnsZoneName`      | string  | The name of the private DNS zone.                                                                                        |                                                                                                                 |
| `virtualNetworkResourceId` | string  | The resource id of the virtual network to link the private DNS zone to.                                                    |                                                                                                                 |
| `registrationEnabled`     | bool    | Indicate if auto-registration of virtual machine records in the virtual network in the Private DNS zone is enabled.       | `false`                                                                                                         |
</details>

### Outputs

There are no outputs for this deployment.

### Deployment

Create the link between the Private DNS Zone and the spoke network:

```bash
az deployment group create \
    --name <deployment-name> \
    --resource-group <resource-group-containing-private-dns-zone> \
    --template-file link-private-dns-to-network.bicep \
    --parameters \
        privateDnsZoneName=<private-dns-zone-name> \
        virtualNetworkResourceId=<virtual-network-resource-id>
```

Replace `<deployment-name>` with a name for the deployment, `<resource-group-containing-private-dns-zone>` with the resource group containing the Private DNS Zone, `<private-dns-zone-name>` with the name of the Private DNS Zone, and `<virtual-network-resource-id>` with the resource id of the virtual network to link the Private DNS Zone to.

> [!NOTE]
> This needs to be done for each Private DNS Zone that needs to be linked to the spoke network, i.e. for the Azure Container Registry and Azure Key Vault.

## Next Steps

After deploying the spoke foundation, you will deploy the supporting services like the Azure Container Registry and the Azure Key Vault.

:arrow_forward: [Supporting Services](../03-Supporting-Services/README.md)
