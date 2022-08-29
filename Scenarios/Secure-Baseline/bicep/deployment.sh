# Set Vars for env check
RHO_PROVIDER=$(az provider show --namespace Microsoft.RedHatOpenShift --query "[registrationState]" --output tsv)
COMP_PROVIDER=$(az provider show --namespace Microsoft.Compute --query "[registrationState]" --output tsv)
STOR_PROVIDER=$(az provider show --namespace Microsoft.Storage --query "[registrationState]" --output tsv)
AUTH_PROVIDER=$(az provider show --namespace Microsoft.Authorization --query "[registrationState]" --output tsv)

#Check if the resource Providers are Installed
if [ "$RHO_PROVIDER" != "Registered" ]; then
    echo "RedHat OpenShift Provider Is Not Installed"
    az provider register --namespace Microsoft.RedHatOpenShift --wait
    echo "RedHat OpenShift Provider has been Installed"
    else
    echo "RedHat Openshift Provider was already installed"
fi
if [ "$COMP_PROVIDER" != "Registered" ]; then
    echo "Microsoft Compute Provider Is Not Installed"
    az provider register --namespace Microsoft.Compute --wait
    echo "Microsoft Compute Provider has been Installed"
    else
    echo "Microsoft Compute Provider was already installed"
fi
if [ "$STOR_PROVIDER" != "Registered" ]; then
    echo "Microsoft Storage Provider Is Not Installed"
    az provider register --namespace Microsoft.RedHatOpenShift --wait
    echo "Microsoft Storage Provider has been Installed"
    else
    echo "Microsoft Storage Provider was already installed"
fi
if [ "$AUTH_PROVIDER" != "Registered" ]; then
    echo "Microsoft Authentication Provider Is Not Installed"
    az provider register --namespace Microsoft.RedHatOpenShift --wait
    echo "Microsoft Authentication Provider has been Installed"
    else
    echo "Microsoft Authentication Provider was already installed"
fi

#Deploy the hub Vnet/routes/etc
az deployment sub create -n "LZ-HUB-ARO" -l "eastus" \
-f 01-Network-Hub/main.bicep \
-p 01-Network-Hub/parameters-main.json --wait

#deploy the bastion VM
az deployment sub create -n "LZ-HUB-ARO-VM" -l "eastus" \
-f 01-Network-Hub/deploy-vm.bicep \
-p 01-Network-Hub/parameters-deploy-vm.json --wait

#Update the HUB UDR
az deployment sub create -n "LZ-HUB-ARO-UDR" -l "eastus" \
-f 01-Network-Hub/updateUDR.bicep \
-p 01-Network-Hub/parameters-updateUDR.json --wait

#Deploy the Spoke Vnet/routes/etc
az deployment sub create -n "LZ-SPOKE-ARO" -l "eastus" \
-f 02-Network-Spoke/main.bicep \
-p 02-Network-Spoke/parameters-main.json --wait

#Deploy the supporting services
az deployment sub create -n "LZ-SUPPORTING-ARO" -l "eastus" \
-f 03-Supporting/main.bicep \
-p 03-Supporting/parameters-main.json --wait

#Deploy the ARO cluster
az deployment sub create -n "LZ-ARO" -l "eastus" \
-f 04-ARO/arocluster.bicep \
-p 04-ARO/params.json --wait


