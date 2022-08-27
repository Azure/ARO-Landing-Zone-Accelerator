## Getting Started with Azure CLI

This section is organized using folders that match the steps outlined below. Make any necessary adjustments to the variables and settings within that folder to match the needs of your deployment.

# Prerequisites  

1. An Azure subscription.

   The subscription used in this deployment cannot be a [free account](https://azure.microsoft.com/free); it must be a standard EA, pay-as-you-go, or Visual Studio benefit subscription. This is because the resources deployed here are beyond the quotas of free subscriptions.

   > :warning: The user or service principal initiating the deployment process _must_ have the following minimal set of Azure Role-Based Access Control (RBAC) roles:
   >
   > * [Contributor role](https://docs.microsoft.com/azure/role-based-access-control/built-in-roles#contributor) is _required_ at the subscription level to have the ability to create resource groups and perform deployments.
   > * [User Access Administrator role](https://docs.microsoft.com/azure/role-based-access-control/built-in-roles#user-access-administrator) is _required_ at the subscription level since you'll be performing role assignments to managed identities across various resource groups.

1. Preqs - Clone this repo, install [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) and [step 1: deploy the resource group](./01-rg.md)
2. [Deploy vnets](./02-vnets.md)
3. [Deploy VMs](./03-vm.md)
4. [Deploy Supporting services](./04-supporting-services.md)
5. [Deploy ARO](./05-aro.md)
6. [Deploy front door](./06-frontdoor.md)
7. [Deploy AAD and configure RBAC](./07-aad.md)
8. [Configure container insights](./08-container-insights.md)
1. [Deploy Sample app](./09-app-deployment.md)
1. [Cleanup]()