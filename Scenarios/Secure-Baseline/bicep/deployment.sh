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
    az provider register --namespace Microsoft.Storage --wait
    echo "Microsoft Storage Provider has been Installed"
    else
    echo "Microsoft Storage Provider was already installed"
fi
if [ "$AUTH_PROVIDER" != "Registered" ]; then
    echo "Microsoft Authentication Provider Is Not Installed"
    az provider register --namespace Microsoft.Authorization --wait
    echo "Microsoft Authorization Provider has been Installed"
    else
    echo "Microsoft Authorization Provider was already installed"
fi

# Prompt user for an Service Principal Name and Subscription ID
echo "Enter the Name of the Service Principal for ARO to use:"
read -r SPNNAME
#echo "Enter the Subscription ID where you want ARO deployed:"
#read -r SUBSCRIPTIONID
SUB_ID=$(az account show | jq -r ".id")

# Create the Service Principal
# TODO: Add check to see if the SPN already exists
az ad sp create-for-rbac --name $SPNNAME --scopes /subscriptions/$SUB_ID --role Contributor --output json > /tmp/sp.json

# Set variables from the Service Principal
SP_CLIENT_ID=$(jq -r '.appId' /tmp/sp.json)
SP_CLIENT_SECRET=$(jq -r '.password' /tmp/sp.json)
SP_OBJECT_ID=$(az ad sp show --id $SP_CLIENT_ID | jq -r '.id')

# Set variable for ARO Provider SP Object ID
ARO_SP_OBJECT_ID=$(az ad sp list --display-name "Azure Red Hat OpenShift RP" --query "[0].id" -o tsv)

#get the value for the pull secret
RHPS=$(cat pullsecret.txt)

echo "The ARO RP SP Object ID is:" $ARO_SP_OBJECT_ID
echo "The APPSP client ID is:" $SP_CLIENT_ID
echo "The APPSP object ID is:" $SP_OBJECT_ID
echo "The APPSP password is:" $SP_CLIENT_SECRET
echo "The redhat pull secret is:" $RHPS
echo "  "
echo "MAKE SURE TO NOTE THESE NOW AS THE APPSP PASSWORD CAN NEVER BE RETRIEVED AGAIN!!!!"
echo "Now would be a good time to check / update your paramaters files with these"
echo " values before continuing this deployment."
echo "  "
echo "press return if ready to proceed.... press CTRL-C to cancel...."
read -r ready

#Deploy the hub Vnet/routes/etc
az deployment sub create -n "LZ-HUB-ARO" -l "eastus" \
-f 01-Network-Hub/main.bicep \
-p 01-Network-Hub/parameters-main.json

#deploy the bastion VM
az deployment sub create -n "LZ-HUB-ARO-VM" -l "eastus" \
-f 01-Network-Hub/deploy-vm.bicep \
-p 01-Network-Hub/parameters-deploy-vm.json

#Update the HUB UDR
az deployment sub create -n "LZ-HUB-ARO-UDR" -l "eastus" \
-f 01-Network-Hub/updateUDR.bicep \
-p 01-Network-Hub/parameters-updateUDR.json

#Deploy the Spoke Vnet/routes/etc
az deployment sub create -n "LZ-SPOKE-ARO" -l "eastus" \
-f 02-Network-Spoke/main.bicep \
-p 02-Network-Spoke/parameters-main.json

#sleep and wait for completion, else route update below will fail
sleep 300

#Update the Spoke Route Table

az deployment sub create -n "LZ-SPOKE-ARO-updateUDR" -l "eastus" \
-f 02-Network-Spoke/updateUDR.bicep \
-p 02-Network-Spoke/parameters-updateUDR.json

#Deploy the supporting services
az deployment sub create -n "LZ-SUPPORTING-ARO" -l "eastus" \
-f 03-Supporting/main.bicep \
-p 03-Supporting/parameters-main.json

#Deploy the ARO cluster
az deployment group create -n "LZ-ARO" -g "spoke-aro" \
-f 04-ARO/arocluster.bicep \
-p aadClientId=${SP_CLIENT_ID} \
-p rpObjectId=${ARO_SP_OBJECT_ID} \
-p aadObjectId=${SP_OBJECT_ID} \
-p aadClientSecret=${SP_CLIENT_SECRET} \
-p rhps=${RHPS} \
-p 04-ARO/params.json


