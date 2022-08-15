# Terraform Deployment
This Terraform deployment uses the `azurerm_resource_group_template_deployment` for the actual ARO deployment. Update to a native provider is currently blocked but is being tracked in [Issue #19](https://github.com/Azure/ARO-Landing-Zone-Accelerator/issues/19). This means that this deployment will only deploy ARO. It cannot be managed via IAC after the initial deployment. Changes to the ARM template or parameters will be ignored in subsequent deployments.

## RedHat OpenShift Provider

The RedHat OpenShift provider is required in the subscription you want to deploy this solution into. The command below will show if the provider has been registered in the subscription.

```bash
az provider show --namespace Microsoft.RedHatOpenShift -o table
```

If this returns a registration status other than `registered`, the command below needs to bue run to register it with the [`az provider`](https://docs.microsoft.com/en-us/cli/azure/provider?view=azure-cli-latest) command

```bash
az provider register --namespace Microsoft.RedHatOpenShift --wait
```

## Service Principals

Terraform will create a service principal for the cluster. This service principal will be used to authenticate to the cluster.

## Deployment

Clone the repository and navigate to the `deployment/terraform` directory.
```bash
git clone https://github.com/Azure/ARO-Landing-Zone-Accelerator

cd deployment/terraform/
```

Run the following commands to deploy the environment.

```bash
terraform init

terraform plan \
  -out aro-deployment.tfplan

terraform apply aro-deployment.tfplan
```

## Known Issues


