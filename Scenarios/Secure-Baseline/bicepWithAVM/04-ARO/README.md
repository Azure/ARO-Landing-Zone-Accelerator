# ARO Secure Baseline - ARO Cluster (Bicep - AVM)

This template deploys an Azure Red Hat OpenShift (ARO) cluster.

## Overview

The template deploy only the Azure Red Hat OpenShift (ARO) cluster. The ARO cluster is deployed in the spoke virtual network.

### Role Assignments

To create the ARO cluster a `service principal` is required. In this documentation, we will call this service principal `ARO Service Principal` or `SP`.

For each tenant there is also a service principal for the ARO resource provider `Azure Red Hat Openshift RP`. In this documentation, we will call this service principal `ARO RP` or `ARO Resource Provider` or `RP SP`.

For both service principals, the following role assignments are required:

- `Network Contributor` on the `Spoke Virtual Network`
- `Network Contributor` on the `Route Table` if User Defined Routing (UDR) is used.
- `Reader` on the `Disk Encryption Set (DES)` if disk encryption is enabled.

> [!NOTE]
> This represents the minimum amount of permissions required to deploy the ARO cluster using the Bicep template.
>
> If you want to deploy with the Azure CLI, you will need additional permissions on the spoke resource group level like `User Access Administrator` to be able to assign the roles for the SP and the RP SP, and `Contributor` to be able to create resources.
>
> If you use want to be able to deploy Azure resources using ARO portal, you will need to add the [Azure Service Operator v2](https://operatorhub.io/operator/azure-service-operator) and be `Contributor` on the spoke resource group or the subscription.

### Parameters

The parameters can be set using the cli command `--parameters <parameter-name>=<value>` or in the parameters file `main.bicepparam`. Below you can find a table with all parameters with. The required parameters are:

- `spokeVirtualNetworkResourceId`: The resource id of the spoke virtual network. This is required to assign `Network Contributor` role to the `ARO Service Principal` and the `ARO RP`.
- `masterNodesSubnetResourceId`: The resource id of the subnet where the master nodes will be deployed.
- `workerNodesSubnetResourceId`: The resource id of the subnet where the worker nodes will be deployed.
- `servicePrincipalClientId`: The client id of the `ARO Service Principal`.
- `servicePrincipalClientSecret`: The client secret of the `ARO Service Principal`.
- `servicePrincipalObjectId`: The object id of the `ARO Service Principal`.
- `aroResourceProviderServicePrincipalObjectId`: The object id of the `ARO RP`.

> [!TIP]
> Most of these required parameters can be get from the outputs of the hub and the spoke deployments using the following commands:
>
> ```bash
> <variable-name>=$(az deployment sub show --name <hub-deployment-name> --query properties.outputs.<output-name>.value -o tsv)
> ```
>
> In `bicepparam` file you can set the client secret and pull secret parameters in the following ways:
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
| `aroClusterName`              | string                | The name of the ARO cluster. Defaults to `<abbreviation-aro>-<workload-name>-<lower-case-env>-<location-short>[-<hash>]`.                                                                                  | `generateResourceName('aroCluster', workloadName, env, location, null, hash)`                       |
| `aroClusterVersion`           | string?               | The version of the ARO cluster (Optional).                                                                    |    `null` (optional parameter)                                                                                                  | 
| `aroClusterDomain`            | string                | The domain to use for the ARO cluster. Defaults to `<workload-name>-<lower-case-env>-<location-short>-<hash-or-unique-string>`.                                                                       | `generateAroDomain(workloadName, env, location, hash, [resourceGroup().id, aroClusterName], 5, 30)`                                                                            |
| `managedResourceGroupName`    | string                | The name of the managed resource group. Defaults to `aro-<domain>-<location>`.                                | `generateResourceName('resourceGroup', workloadName, env, location, 'managed-aro', hash)`           |
| `pullSecret`                  | string?               | The pull secret for the ARO cluster.                                                                          |   `null` (optional parameter)                                                                                                  |
| `apiServerVisibility`         | visibilityType        | The visibility of the API server. Defaults to `Private`.                                                      | `'Private'`                                                                                         |
| `ingressVisibility`           | visibilityType        | The visibility of the ingress. Defaults to `Private`.                                                         | `'Private'`                                                                                         |
| `enableFipsValidatedModules`  | bool                  | Enable FIPS validated modules. Defaults to false.                                                              | `false`                                                                                             |
| `masterNodesVmSize`           | masterNodesVmSizeType | The VM size to use for the master nodes. Defaults to `Standard_D8s_v5`.                                        | `'Standard_D8s_v5'`                                                                                 |
| `encryptionAtHostMasterNodes` | encryptionAtHostType  | Enable encryption at host for the master nodes. Defaults to `Enabled`.                                         | `'Enabled'`                                                                                         |
| `workerProfile`               | workerProfileType     | The worker profile to use for the ARO cluster.                                                                | `{ name: 'worker', count: 3, vmSize: 'Standard_D4s_v3', diskSizeGB: 128, encryptionAtHost: 'Enabled' }` |
| `spokeVirtualNetworkResourceId`           | string  | The resource id of the spoke virtual network. This is required for role assignment for the ARO cluster. |                 |
| `podCidr`                                 | string  | The CIDR for the pods. Defaults to `10.128.0.0/14`.                                                     | `10.128.0.0/14` |
| `serviceCidr`                             | string  | The CIDR for the services. Defaults to `172.30.0.0/16`.                                                  | `172.30.0.0/16` |
| `masterNodesSubnetResourceId`             | string  | The resource id of the subnet to use for the master nodes.                                              |                 |
| `workerNodesSubnetResourceId`             | string  | The resource id of the subnet to use for the worker nodes.                                               |                 |
| `servicePrincipalClientId`                | string  | The client id of the service principal.                                                                  |                 |
| `servicePrincipalClientSecret`            | string  | The client secret of the service principal.                                                              |                 |
| `servicePrincipalObjectId`                | string  | The object id of the service principal.                                                                  |                 |
| `aroResourceProviderServicePrincipalObjectId` | string  | The object id of ARO resource provider service principal.                                           |                 |
| `routeTableResourceId`         | string? | The resource id of the route table (Optional). If the name is not set the outbound type will be `loadbalancer`. This is required to configure UDR for the ARO cluster.                                                              |   `null` (optional parameter)            |
| `firewallPrivateIpAddress`     | string? | The private IP address of the firewall (Optional). This is required to configure UDR for the ARO cluster. If not set, UDR is not configured and the outbound type of the ARO cluster is set to `Loadbalancer`.                        |  `null` (optional parameter)             |
| `diskEncryptionSetResourceId`  | string? | The resourceId of the security resource group (Optional). If set the disk encryption set will be used for the ARO cluster.                                                                                                            |  `null` (optional parameter)             |
</details>

### Outputs

There are no outputs for this template.

## Deployment

Before you can deploy the ARO cluster, you need to create the `ARO Service Principal` and get the object id of the `ARO RP`:

1. Create a service principal for the ARO cluster:

    ```bash
    SP=$(az ad sp create-for-rbac --name <service-principal-name>)
    ```

    Replace `<service-principal-name>` with the name of the service principal.

1. Get the credientals of the service principal:

    ```bash
    SP_CLIENT_ID=$(echo $SP | jq -r '.appId')
    SP_CLIENT_SECRET=$(echo $SP | jq -r '.password')
    ```

1. Get the object id of the service principal:

    ```bash
    SP_OBJECT_ID=$(az ad sp show --id $SP_CLIENT_ID --query "id" -o tsv)
    ```

1. Get the object id of the ARO resource provider:

    ```bash
    ARO_RP_SP_OBJECT_ID=$(az ad sp list --display-name "Azure Red Hat OpenShift RP" --query [0].id -o tsv)
    ```

Now that you have the required parameters, you can deploy the ARO cluster:


1. Navigate to the directory containing the Bicep file.

    ```bash
    cd ../04-ARO
    ```

1. Deploy the template:

    ```bash
    az deployment group create \
        --name <deployment-name> \
        --resource-group <spoke-resource-group> \
        --template-file main.bicep \
        --parameters ./main.bicepparam \
        --parameters \
            servicePrincipalClientId=$SP_CLIENT_ID \
            servicePrincipalClientSecret=$SP_CLIENT_SECRET \
            servicePrincipalObjectId=$SP_OBJECT_ID \
            aroResourceProviderServicePrincipalObjectId=$ARO_RP_SP_OBJECT_ID
    ```

    Replace `<deployment-name>` with the name of the deployment and `<spoke-resource-group>` with the name of the spoke resource group.

# Next Step

Now that the ARO cluster is deployed, it is time to deploy your first workload. If you don't want to deploy the sample workload, you can skip this step and go to the next step: deploy Azure Front Door.

:arrow_forward: [Deploy Sample Workload](../05-Workload/README.md)
:arrow_forward: [Deploy Azure Front Door](../06-AFD/README.md)
