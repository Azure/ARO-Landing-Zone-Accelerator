# ARO Secure Baseline - Front Door (Bicep - AVM)

This Bicep template deploys Azure Front Door and related components for the ARO cluster.

## Overview

**Targeted Scope**: Resource Group (e.g. Spoke Resource Group)

This template deploys the following resources:

1. Web Application Firewall (WAF) Policy: Used to protect the Front Door endpoint.
2. Private Link Service: Connects the Front Door to the ARO cluster's internal load balancer.
3. Azure Front Door Profile: The main Front Door resource that manages the global routing and caching.
   - Endpoint: The public endpoint for the Front Door.
   - Origin Group: Groups the origins (backends) for the Front Door.
   - Origin: Represents the ARO cluster as a backend for the Front Door.

### Parameters

The parameters can be set using the cli command `--parameters <parameter-name>=<value>` or in the parameters file `main.bicepparam`. Below you can find a table with all parameters. The required parameters are:

- `internalLoadBalancerResourceId`: The resource ID of the internal load balancer for the ARO cluster.
- `frontDoorSubnetResourceId`: The resource ID of the front door subnet.
- `originHostName`: The hostname of the ARO cluster's API server or application endpoint.

<details>
<summary>Table with all parameters</summary>

| Name                             | Type   | Description                                                                                                                | Default Value                                                                                           |
|----------------------------------|--------|----------------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------|
| `workloadName`                   | string | The name of the workload. Defaults to aro-lza.                                                                              | `'aro-lza'`                                                                                             |
| `location`                       | string | The location of the resources. Defaults to the deployment location.                                                         | `resourceGroup().location`                                                                              |
| `env`                            | string | The type of environment. Defaults to DEV.                                                                                   | `'DEV'`                                                                                                 |
| `hash`                           | string | The hash to be added to every resource name. If not set, a unique string is generated.                                      | `null` (optional parameter)                                                                             |
| `tags`                           | object | The tags to apply to the resources.                                                                                         | Object with `environment`, `workload`, and optionally `hash`                                            |
| `wafPolicyName`                  | string | Name of the Front Door Web Application Firewall (WAF) policy                                                                | Generated using `generateUniqueGlobalName` function                                                     |
| `privateLinkServiceName`         | string | Name of the Private Link Service                                                                                            | Generated using `generateResourceName` function                                                         |
| `internalLoadBalancerResourceId` | string | Resource ID of the internal Load Balancer                                                                                   |                                                                                                          |
| `frontDoorSubnetResourceId`    | string | Resource ID of the Azure Front Door subnet Subnet                                                                                            |                                                                                                          |
| `frontDoorProfileName`           | string | Name of the Azure Front Door profile                                                                                        | Generated using `generateResourceName` function                                                         |
| `endpointName`                   | string | Name of the endpoint                                                                                                        | `'endpoint-${substring(uniqueString(resourceGroup().id), 0, 6)}'`                                      |
| `originGroupName`                | string | Name of the origin group                                                                                                    | `'default-origin-group'`                                                                                |
| `originName`                     | string | Name of the origin                                                                                                          | `'default-origin'`                                                                                      |
| `originHostName`                 | string | Hostname of the origin                                                                                                      |                                                                                                          |

</details>

### Outputs

These are the outputs of the template:

| Output                  | Type   | Description                                      |
|-------------------------|--------|--------------------------------------------------|
| `privateLinkServiceName`| string | The name of the created Private Link Service     |
| `frontDoorFQDN`         | string | The FQDN of the Front Door endpoint              |

These outputs can be used in subsequent deployments or for accessing the Front Door endpoint.

## Deployment

To deploy the Front Door and related components, follow these steps:

1. Navigate to the directory containing the Bicep file.

    ```bash
    cd ../05-Front-Door
    ```

2. Deploy the template:

    ```bash
    az deployment group create \
        --name <deployment-name> \
        --resource-group <spoke-resource-group> \
        --template-file main.bicep \
        --parameters ./main.bicepparam
    ```

    Replace `<deployment-name>` with the name of the deployment and `<spoke-resource-group>` with the name of the spoke resource group.

## Next Step

After deploying the Front Door and related components, you can proceed to configure your applications to use the Front Door endpoint for improved global access and security. If you'd like you can deploy a sample app following the instructions in the next folder.

:arrow_forward: [Deploy Sample App](../06-Sample-App/README.md)