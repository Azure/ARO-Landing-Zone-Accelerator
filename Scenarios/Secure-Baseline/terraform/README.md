# Terraform Deployment

This Terraform deployment will deploy a secure baseline Azure RedHat Openshift (ARO) cluster. This deployment is based on the [Azure Red Hat OpenShift Landing Zone Accelerator](https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/scenarios/app-platform/azure-red-hat-openshift/landing-zone-accelerator) documentation. There is a [single Terraform deployment](main.tf) that will deploy the following:

- Hub and Spoke Network Topology
- Hub resource group with the following resources:
  - [Log Analytics Workspace](main.tf)
  - [Azure Firewall](modules/vnet/firewall.tf)
  - [Virtual Network](modules/vnet/hub.tf)
  - [Key Vault](modules/keyvault/keyvault.tf)
  - [UDR](modules/vnet/udr.tf)
  - [Bastion Host and 2 jumpboxes](modules/vm/vm.tf)
- Spoke resource group
  - [Virtual Network](modules/vnet/spoke.tf)
  - Supporting Services:
    - [Azure Container Registry](modules/supporting/acr.tf)
    - [Key Vault](modules/supporting/sup_kv.tf)
    - [Cosmos DB](modules/supporting/cosmos.tf)
    - [Azure RedHat Openshift Cluster](modules/aro/aro.tf)
    - [Front Door](modules/supporting/frontdoor.tf)
- [Service Principal](modules/serviceprincipal/serviceprincipal.tf) with `Contributor` role on both Hub and Spoke virtual networks

### Log Analytics Workspace

Log Analytics Workspace is deployed to the hub resource group. It is used to collect logs from the spoke and the hub. If you prefer to use a different Log Analytics Workspace for your ARO workloads, you can deploy one in the spoke and update the terraform templates to ensure that the spoke resources use it.

### UDR

UDR should be implemented in the spoke network. This is a temporary implementation and will be moved to the spoke network in a future release.

The service principal should not have the contributor role on the hub virtual network, only on the spoke virtual network. This is a temporary implementation due to the presence of UDR in the HUB resource group.

### Hub Key Vault

The hub key vault provides public access and is deployed to store the credentials of the jumpboxes.

### Front Door

Front door use the private IP address of the internal load balancer of the ARO cluster. This internal load balancer is part of the control planed of the ARO cluster and is managed by Azure.

## Terraform State Management

In this example, state is to be stored in an Azure Storage Account. The storage account is not created as part of the terraform templates but it is the first step of the deployment. All deployments reference this storage account to either store state or reference variables from other parts of the deployment however you may choose to use other tools for state management, like Terraform Cloud after making the necessary code changes.

> **IMPORTANT**
> 
> Azure RedHat OpenShift (ARO) cluster is deployed using an ARM template. Indeed the terraform deployment is using the [azurerm_resource_group_template_deployment](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group_template_deployment) resource. This means that this is a one time install. Running this Terraform deployment as Infrastructure as Code will allow management of the environment supporting ARO but not ARO itself. Changes made to ARO after the initial deployment will be ignored. When a proper ARO provider will be available, this deployment will be updated to use it.
>

## Prerequisites

1. Install the following component:

    * [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
    * [jq](https://stedolan.github.io/jq/)
    * [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)

1. Clone this repository

    ```bash
    git clone https://github.com/Azure/ARO-Landing-Zone-Accelerator.git
    ```

1. Authenticate with Azure CLI

    ```bash
    az login
    ```

1. Set a specific subscription

    ```bash
    az account list --output table
    az account set --subscription <name-of-subscription>
    ```

1. Register the RedHatOpenShift provider

    ```bash
    az provider register --namespace Microsoft.RedHatOpenShift --wait
    ```

1. Identify the resource provider id for ARO. You'll need it later.

    - `Bash`:

        ```bash
        ARO_RP_OBJECT_ID=$(az ad sp list --display-name "Azure Red Hat OpenShift RP" --query "[0].id" -o tsv)
        echo $ARO_RP_OBJECT_ID
        ```

    - `PowerShell`:

        ```powershell
        $ARO_RP_OBJECT_ID = az ad sp list --display-name "Azure Red Hat OpenShift RP" --query "[0].id" -o tsv
        Write-Output $ARO_RP_OBJECT_ID
        ```

1. Create the storage account for state management

    1. Define some variables

        - `Bash`:

            ```bash
            REGION=<REGION>
            STORAGEACCOUNTNAME=<UNIQUENAME>
            CONTAINERNAME=arolzaterraform
            TFSTATE_RG=rg-aro-lza-terraform
            ```

        - `PowerShell`:

            ```powershell
            $REGION="<REGION>"
            $STORAGEACCOUNTNAME="<UNIQUENAME>"
            $CONTAINERNAME="arolzaterraform"
            $TFSTATE_RG="rg-aro-lza-terraform"
            ```
        Where `<REGION>` is the region where you want to deploy the storage account and `<UNIQUENAME>` is a unique name for the storage account.

    1. Create the resource group

        ```bash
        az group create --name $TFSTATE_RG --location $REGION
        ```
    
    1. Create the storage account

        ```bash
        az storage account create --name $STORAGEACCOUNTNAME --resource-group $TFSTATE_RG --location $REGION --sku Standard_GRS
        ```

    1. Create the storage container within the storage account

        ```bash
        az storage container create --name $CONTAINERNAME --account-name $STORAGEACCOUNTNAME --resource-group $TFSTATE_RG
        ```

1. Review carrefully the implementation of the LZA and all the parameters before deploying the solution.

    > **Important**
    >
    >The service principal required for ARO with a `Contributor` role on the spoke virtual network is created as part of this deployment. If you don't have the rights to create it with the deployment. Create it before running the deployment and pass the object id as a parameter to the deployment. You will need to update the terraform templates to use the object id instead of creating the service principal.
    >
    > This is true for any resource. In the future the LZA will provide more flexibility to use existing resources. Even with using existing resources, ensure to review carefully the parameters and the implementation of the LZA before deploying it to guarantee that it is aligned with your requirements and policies.
    >

## Deployment steps

To deploy the landing zone, follow the steps below.

> **Note**
>
> For Powershell, replace `\` with ``` ` ```.
>

1. Initialize Terraform

    ```bash
    terraform init -backend-config="resource_group_name=$TFSTATE_RG" -backend-config="storage_account_name=$STORAGEACCOUNTNAME" -backend-config="container_name=$CONTAINERNAME"
    ```

1. Set the following parameters:

    - `Bash`:
        
        ```bash
        TENANT_ID=$(az account show --query tenantId -o tsv)
        SUBSCRIPTION_ID=$(az account show --query id -o tsv)
        LOCATION=<YOUR_REGION>
        ARO_BASE_NAME=<YOUR_ARO_CLUSTER_BASENAME>
        ARO_DOMAIN=<YOU_ARO_UNIQUE_DNS_NAME>
        ```

    - `PowerShell`:

        ```powershell
        $TENANT_ID = az account show --query tenantId -o tsv
        $SUBSCRIPTION_ID = az account show --query id -o tsv
        $LOCATION="<YOUR_REGION>"
        $ARO_BASE_NAME="<YOUR_ARO_CLUSTER_BASENAME>"
        $ARO_DOMAIN="<YOU_ARO_UNIQUE_DNS_NAME>"
        ```

    Where `<YOUR_REGION>` is the region where you wamt to deploy the landing zone, `<YOUR_ARO_CLUSTER_BASENAME>` is the base name for the ARO cluster and `<YOU_ARO_UNIQUE_DNS_NAME>` is the unique DNS name for the ARO cluster.

    > **Note**
    >
    > You can also set the parameters in [variables.tf](variables.tf) file. If you are adding the parameters in the variables file, you need to remove all the `-var ...=$...` from the 2 next steps.
    >

    <details>
    <summary>Click to see the full list of parameters.</summary>

    | Name              | Required | Default Value | Description       |
    | ----------------- | -------- | ------------- | ----------------- |
    | tenant_id         |    x     |               | The tenant ID     |
    | subscription_id   |    x     |               | The subscription ID |
    | location          |          | "eastus"      | The location of the resources |
    | hub_name          |          | "hub-aro"     | The name of the hub |
    | spoke_name        |          | "spoke-aro"   | The name of the spoke |
    | aro_spn_name      |          | "aro-lza-sp"  | The name of the ARO service principal |
    | aro_rp_object_id  |    x     |               | The object ID of the ARO resource provider |
    | aro_base_name     |    x     |               | The base name for ARO resources |
    | aro_domain        |    x     |               | The domain for ARO resources |

    </details>

1. Validate the configuration

    ```bash
    terraform plan \
      -var tenant_id= $TENANT_ID \
      -var subscription_id=$SUBSCRIPTION_ID \
      -var location=$LOCATION \
      -var aro_rp_object_id= $ARO_RP_OBJECT_ID \
      -var aro_base_name=$ARO_BASE_NAME \
      -var aro_domain=$ARO_DOMAIN
    ```

    
1. Deploy the landing zone

    ```bash
    terraform apply \
      --auto-approve \
      -var tenant_id= $TENANT_ID \
      -var subscription_id=$SUBSCRIPTION_ID \
      -var location=$LOCATION \
      -var aro_rp_object_id= $ARO_RP_OBJECT_ID \
      -var aro_base_name=$ARO_BASE_NAME \
      -var aro_domain=$ARO_DOMAIN
    ```

## Post Deployment Tasks

There are a few tasks that need to be completed after the deployment. For some tasks there are scripts to be run from one of the jumpbox. The jumpboxes are created during the deployment (read how to get credentials below).

These are the post deployment tasks:

* [AAD Integration](./post_deployment/aad-RBAC)
* [Container Insights Integration](./post_deployment/containerinsights)
* [Application Deployment](./post_deployment/appdeployment)
* Disable `kubeadmin` login

### Retrieve Jumpbox and ARO credentials

To retrieve the credentials for the jumpboxes, you need to be Secret Officer on the hub key vault. Then you can execute the following commands:

```bash
az keyvault secret show --name "vmadminusername" --vault-name "<your-unique-keyvault-name>" --query "value"
az keyvault secret show --name "vmadminpassword" --vault-name "<your-unique-keyvault-name>" --query "value"
```

Where `<your-unique-keyvault-name>` is the name of the key vault created during the deployment.

> **Note**
>
> * The credentials are the same for the Linux and the Windows jumpboxes.
> * Windows jumpbox can be used to access Azure portal and RedHat Openshift portal using a remote desktop client.
> * For CI/CD and CLI commands, either use the Linux jumpbox or the Windows jumpbox.
>

## Cleanup

1. Delete the ARO cluster

    ```bash
    az aro delete --resource-group <SPOKE_RESOURCE_GROUP_NAME> --name <ARO_CLUSTER_NAME> -y
    ```

    Where `<SPOKE_RESOURCE_GROUP_NAME>` is the name of the spoke resource group and `<ARO_CLUSTER_NAME>` is the name of the ARO cluster.

1. Delete the resource groups

    ```bash
    az group delete -n <SPOKE_RESOURCE_GROUP_NAME> -y
    az group delete -n <HUB_RESOURCE_GROUP_NAME> -y
    ```

    Where `<SPOKE_RESOURCE_GROUP_NAME>` is the name of the spoke resource group and `<HUB_RESOURCE_GROUP_NAME>` is the name of the hub resource group.

## Known Issues

There is no ARO Terraform provider so this deployment uses an ARM template for the ARO deployment. This means that this is a one time install. Running this Terraform deployment as Infrastructure as Code will allow management of the environment supporting ARO but not ARO itself. Changes made to ARO after the initial deployment will be ignored.
