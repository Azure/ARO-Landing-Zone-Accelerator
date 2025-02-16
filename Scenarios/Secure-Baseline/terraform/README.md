# Terraform Deployment


A deployment of ARO-hosted workloads typically requires a separation of duties and lifecycle management in different areas, such as prerequisites, the host network, cluster infrastructure, the shared services, and the application workloads themselves. This reference implementation is no different.

There are various ways to secure your ARO cluster. From a network security perspective, these can be classified into securing the control plane and securing the workload. When it comes to securing the control plane, one of the best ways to do that is by using a private cluster, where the control plane or API server has internal IP addresses that are defined in the [RFC1918 - Address Allocation for Private Internet](https://datatracker.ietf.org/doc/html/rfc1918) document. By using a private cluster, you can ensure network traffic between your API server and your node pools remains on the private network only.

This reference architecture is designed to deploy a secure baseline ARO cluster following the [Hub and Spoke network topology](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/hub-spoke-network-topology). The complete architecture is illustrated in the diagram below:

![Architectural diagram for the secure baseline scenario.](./media/aro_landing_zone_Architecture.png)

## Core Architecture Components

This Terraform deployment will deploy a secure baseline Azure RedHat Openshift (ARO) cluster. This deployment is based on the [Azure Red Hat OpenShift Landing Zone Accelerator](https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/scenarios/app-platform/azure-red-hat-openshift/landing-zone-accelerator) documentation. There is a [single Terraform deployment](main.tf) that will deploy the following:

- Hub and Spoke Network Topology
- Hub resource group with the following resources:
  - [Log Analytics Workspace](main.tf) used to collect log data centrally.
  - [Azure Firewall](modules/vnet/firewall.tf) used to protect the hub virtual network and its peered networks from unwanted traffic.
  - [Virtual Network](modules/vnet/hub.tf) Hub virtual network: the central point of connectivity to the on-premises network and the internet
  - [Key Vault](modules/keyvault/keyvault.tf) used to store users credentials to access management VMs
  - [Bastion Host and 2 jumpboxes](modules/vm/vm.tf) host used to provide secure RDP and SSH connectivity to the virtual machines in the spoke virtual networks
- Spoke resource group
  - [Virtual Network](modules/vnet/spoke.tf) the virtual network where the ARO cluster is deployed
  - [UDR](modules/vnet/udr.tf) is used to redirect all egress traffic from the spoke to the azure firewall in the hub.
  - [Azure RedHat Openshift Cluster](modules/aro/aro.tf) fully managed Openshift cluster that is monitored and operated jointly by Microsoft and Red Hat.
  - [Front Door](modules/supporting/frontdoor.tf) is used to route external traffic to workloads deployed on the ARO cluster.
  - [Service Principal](modules/serviceprincipal/serviceprincipal.tf) with `Contributor` role on both Hub and Spoke virtual networks
  - Supporting Services:
    - [Azure Container Registry](modules/supporting/acr.tf) used to store and manage container images for the ARO cluster.
    - [Key Vault](modules/supporting/sup_kv.tf) used to store and manage sensitive information such as secrets, keys, and certificates.


## Prerequisites

All commands will be using bash - if you are using a Windows machine, you can either use [Git Bash](https://git-scm.com/downloads) or [WSL2](https://learn.microsoft.com/en-us/windows/wsl/install) (prefered).

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

1. Register the following providers

    ```bash
    az provider register --namespace 'Microsoft.RedHatOpenShift' --wait
    az provider register --namespace 'Microsoft.Compute' --wait
    az provider register --namespace 'Microsoft.Storage' --wait
    az provider register --namespace 'Microsoft.Authorization' --wait
    ```

     
## Terraform State Management

In this example, state is to be stored in an Azure Storage Account. The storage account is not created as part of the terraform templates but it is the first step of the deployment. All deployments reference this storage account to either store state or reference variables from other parts of the deployment however you may choose to use other tools for state management, like Terraform Cloud after making the necessary code changes.

1. Define some variables:

    ```bash
    REGION=<REGION>
    STORAGEACCOUNTNAME=<UNIQUENAME>
    CONTAINERNAME=arolzaterraform
    TFSTATE_RG=rg-aro-lza-terraform
    ```

    Where `<REGION>` is the region where you want to deploy the storage account and `<UNIQUENAME>` is a unique name for the storage account.

1. Create the resource group:

    ```bash
    az group create --name $TFSTATE_RG --location $REGION
    ```

1. Create the storage account:

    ```bash
    az storage account create --name $STORAGEACCOUNTNAME --resource-group $TFSTATE_RG --location $REGION --sku Standard_GRS
    ```

1. Create the storage container within the storage account:

    ```bash
    az storage container create --name $CONTAINERNAME --account-name $STORAGEACCOUNTNAME --resource-group $TFSTATE_RG
    ```


## Deployment steps

Review carefully the implementation of the LZA and all the parameters before deploying the solution.

> **Important**
>
> The service principal required for ARO with a `Contributor` role on the spoke virtual network is created as part of this deployment. If you don't have the rights to create it with the deployment, create it before running the deployment and pass the object ID as a parameter to the deployment. You will need to update the Terraform templates to use the object ID instead of creating the service principal.
>
> This is true for any resource. In the future, the LZA will provide more flexibility to use existing resources. Even when using existing resources, ensure to review carefully the parameters and the implementation of the LZA before deploying it to guarantee that it is aligned with your requirements and policies.
>

1. Review and configure terraform variable in variables.tf file.

The following table provide a list of all variables available.
You must provide a value to all variables set as required, you can chose to customize or keep default value for the other variables.

    <details>
    <summary>Click to see the full list of parameters.</summary>

    | Name                | Required | Default Value | Description                                      |
    | ------------------- | -------- | ------------- | ------------------------------------------------ |
    | tenant_id           |    x     |               | The Entra tenant ID                              |
    | subscription_id     |    x     |               | The Azure subscription ID                        |
    | location            |          | "eastasia"    | The location of the resources                    |
    | hub_name            |          | "hub-lz-aro"  | The name of the hub                              |
    | spoke_name          |          |"spoke-lz-aro" | The name of the spoke                            |
    | aro_spn_name        |          | "aro-lz-sp"   | The name of the ARO service principal            |
    | aro_rp_object_id    |    x     |               | The object ID of the ARO resource provider       |
    | aro_base_name       |          | "aro-cluster" | The ARO cluster name                             |
    | aro_domain          |    x     |               | The domain for ARO resources - must be unique    |
    | vm_admin_username   |          | "arolzadmin"  | The admin username for the virtual machines      |
    | rh_pull_secret      |          |    null       | RH pull secret to enable operators and registries|

    </details>

you can retrieve your tenantid, subscriptionid and aro resource provider id with the following commands:

```bash
    ARO_RP_OBJECT_ID=$(az ad sp list --display-name "Azure Red Hat OpenShift RP" --query "[0].id" -o tsv)
    echo $ARO_RP_OBJECT_ID

    TENANT_ID=$(az account show --query tenantId -o tsv)
    echo $TENANT_ID

    SUBSCRIPTION_ID=$(az account show --query id -o tsv)
    echo $SUBSCRIPTION_ID
```

If you wish to customize the ARO Cluster specs such as VM Size for control plane and worker nodes or the number of nodes - you will need to edit the [variable.tf](./modules/aro/aro_variables.tf) in the aro module and change the values for aro_version, main_vm_size, worker_vm_size and worker_node_count.

> **Important**
>
> Updating the rh_pull_secret value for an existing cluster will redeploy the ARO cluster.
>

1. Initialize Terraform

 Variables should already been set from the account storage creation step.

```bash
terraform init -backend-config="resource_group_name=$TFSTATE_RG" -backend-config="storage_account_name=$STORAGEACCOUNTNAME" -backend-config="container_name=$CONTAINERNAME"
```

1. Validate the configuration

    ```bash
    terraform plan
    ```

    
2. Deploy the landing zone

    ```bash
    terraform apply --auto-approve
    ```

## Post Deployment Tasks

### Retrieve Jumpbox and ARO credentials

To retrieve the credentials for the jumpboxes, you need to be Secret Officer on the hub key vault. Then you can execute the following command to retrieve the password for default user "arolzadmin":

```bash
az keyvault secret show --name "vmadminpassword" --vault-name "<your-unique-keyvault-name>" --query "value"
```

Where `<your-unique-keyvault-name>` is the name of the key vault created during the deployment in the hub resource group.

> **Note**
>
> * The credentials are the same for the Linux and the Windows jumpboxes.
> * Windows jumpbox can be used to access Azure portal and RedHat Openshift portal using a remote desktop client.
> * For CI/CD and CLI commands, either use the Linux jumpbox or the Windows jumpbox.
> * both jumpboxes will have tools preinstalled: azure cli, kubectl, oc, helm. The windows jumpbox will also have VSCode and Git installed.
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

