# Terraform Deployment

This Terraform deployment uses the `azurerm_resource_group_template_deployment` for the actual ARO deployment. Update to a native provider is currently blocked but is being tracked in [Issue #19](https://github.com/Azure/ARO-Landing-Zone-Accelerator/issues/19). This means that this deployment will only deploy ARO. It cannot be managed via IAC after the initial deployment. Changes to the ARM template or parameters will be ignored in subsequent deployments.


## Prerequisites
Before you run the commands, you need to create a service principal that will be used by ARO in Azure. You also need to have the following installed:
* [jq](https://stedolan.github.io/jq/)
* [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)

## Deployment steps
To run the deployment, execute the commands in "Scenarios\Secure-Baseline\terraform\deploy.azcli" file. 
This deployment uses a single Azure CLI script to do the following:

* Checks to if Terraform is installed. Terraform is required for this deployment. More information on how to install Terraform can be found [here](https://www.terraform.io/docs/commands/install.html).
* Checks your Azure Subscription to see if the RedHatOpenShift provider is enabled. If it is not enabled, it will be enabled.
* Asks the user to provide the name to be used for the Service Principal it will create.
* Asks the user to provide the Subscription ID where ARO is to be deployed.
* Creates the SP based on the name provided.
* Gets the SP for the ARO Provider
* Initializes Terraform
* Deploys the environment

## Retrieve Jumpbox and ARO credentials
add description or commands to retrieve kv secrets for username and password required to connect on jumpbox with bastion (same credentials for windows and linux)
i would suggest also to add a note highlighting that windowsbox is meant for Azure and ARO portal access for tasks done using UI. For AZCLI commands either linux subsystem for windows is recommanded or use the linux jumpbox.


## Post Deployment Tasks

There are a few tasks that need to be completed after the deployment. These scripts must be run from the Jumpbox that is created during the deployment. These scripts are in the files in the folders listed below.

* [AAD Integration](./post_deployment/aad-RBAC/aad-RBAC)
* [Container Insights Integration](./post_deployment/containerinsights)
* [Application Deployment](./post_deployment/appdeployment)

## Cleanup
In this step you will delete all the resources that were created during the previous steps.

Execute the code in the "Scenarios\Secure-Baseline\delete.azcli" file.

## Known Issues

There is no ARO Terraform provider so this deployment uses an ARM template for the ARO deployment. This means that this is a one time install. Running this Terraform deployment as Infrastructure as Code will allow management of the environment supporting ARO but not ARO itself. Changes made to ARO after the initial deployment will be ignored.
