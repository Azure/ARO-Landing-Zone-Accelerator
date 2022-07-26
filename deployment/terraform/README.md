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

ARO needs a service principal to deploy. the command below will create the SP.

```bash
SPNAME=<service_principal> # The name of the SP ARO will use
SUB_ID=<subscription id> # The ID of the subscription where ARO will be deployed
TENANT_ID=<Tenant ID> # The ID of the Azure tenant in which ARO is deployed
az ad sp create-for-rbac --role Contributor --scopes /subscriptions/$SUB_ID --name $SPNAME > app-service-principal.json
SP_CLIENT_ID=$(jq -r '.appId' app-service-principal.json)
SP_CLIENT_SECRET=$(jq -r '.password' app-service-principal.json)
SP_OBJECT_ID=$(az ad sp show --id $SP_CLIENT_ID | jq -r '.id')
```

You will also need the Service Principal object ID for the OpenShift resource provider.

```bash
ARO_RP_SP_OBJECT_ID=$(az ad sp list --display-name "Azure Red Hat OpenShift RP" --query [0].id -o tsv)
```

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
  -var tenant_id="$TENANT_ID" \
  -var subscription_id="$SUB_ID" \
  -var aro_sp_object_id="$SP_OBJECT_ID" \
  -var aro_sp_password="$SP_CLIENT_SECRET" \
  -var aro_rp_object_id="$ARO_RP_SP_OBJECT_ID"

terraform apply \
  -var tenant_id="$TENANT_ID" \
  -var subscription_id="$SUB_ID" \
  -var aro_sp_object_id="$SP_OBJECT_ID" \
  -var aro_sp_password="$SP_CLIENT_SECRET" \
  -var aro_rp_object_id="$ARO_RP_SP_OBJECT_ID"
```

## Known Issues

There is no ARO Terraform provider so this deployment uses an ARM template for the ARO deployment. This means that this is a one time install. Running this in a pipeline or as a state managed deployment will result in errors.
