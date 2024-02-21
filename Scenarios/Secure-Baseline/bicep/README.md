# ARO Secure Baseline - Bicep

> [!CAUTION]
> **THIS IMPLEMENTATION IS EXPERIMENTAL AND MIGHT NOT WORK. USE the Terraform option instead.**


> This deployment method currently expects the usage of Azure DevOps or deployment.sh script.

## Azure Devops Instructions
### Portal / integration configuration:

Begin by configuring an azure devops org and project at devops.azure.com
Add service connections to your company's azure account. Do not select a resource group!
  (this deployment method currently requires the ability to deploy by subscription)
add service connection to your company's github portal
connect the azure pipelines github app to the repo you wish to use for this deployment

### Pipeline creation

This step is a bit tricky.  Azure Devops wants to create a pipeline in the main branch
of the repo and in the root folder of the repo.  Since this particular exercise uses 
multiple deployment examples, it is better to keep the pipeline JSON file in the bicep 
folder.  To do this, follow these steps.  Else, just keep and modify the example to your 
requirements.

- Create a new started pipeline in your main branch using the azure devops portal.
- Using an IDE (like VSCode) create a new .yml file in the bicep filder and name it as you 
  choose.  For this exercise, it is named azure-pipelines.yml.  Copy / paste the contents 
  of the starter pipeline into this new file.
- Delete the pipeline in the Azure devops portal.
- Save and commit/push the repo to github
- Create a new pipeline and this time, select the azure-pipelines.yml file located in the 
  bicep branch, and in the bicep folder.
- don't forget to change the trigger branch in pipeline definition.
 
### Pipeline / script steps:

1.  Create the Hub network and all hub resources
    - Hub resource group
    - Hub vnet and all subnets
    - route table and routes
    - azure bastion service
2.  Create the Bastion Host VM
    - Currently set to RHEL 9.
3.  Update the hub route table to allow bastion VM internet access
4.  Create the spoke network and all spoke resources
    - Spoke resource group
    - Spoke Vnet and subnets
    - Private endpoints
    - Private DNS zones
    - spoke route table and routes
5. Update the spoke routing table with the master and worker spoke subnets
6.  Create the supporting services for the ARO cluster
    - azure container registry
    - azure storage account
    - azure keyvault
7.  Create the ARO cluster.

This is still under development.  Many things will require adjustment / tailoring to the with manual intervention.
